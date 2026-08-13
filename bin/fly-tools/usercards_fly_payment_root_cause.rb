#!/usr/bin/env ruby
# frozen_string_literal: true

# Фаза 3.2 — root cause платежа без RebillId на Fly prod.
#
#   ruby bin/fly-tools/usercards_fly_payment_root_cause.rb
#   UC_PAYMENT_ID=8866531465 ruby bin/fly-tools/usercards_fly_payment_root_cause.rb

require "json"
require "open3"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
PAYMENT_UUID = ENV.fetch("UC_PAYMENT_UUID", "f7a61e93-0d6f-4f05-9221-e3461b01dd30")
TBANK_PAYMENT_ID = ENV.fetch("UC_PAYMENT_ID", "8866531465")
CONTROL_UUID = ENV.fetch("UC_CONTROL_UUID", "bff277bd-6e18-468c-8758-5d8e3bca4422")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/usercards_save_card",
  "usercards_fly_payment_root_cause_#{DATE}.json"
)

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
  web ||= machines.find { |m| m["state"] == "started" }
  web&.dig("id") || raise("no started fly machine")
end

def fly_runner(machine_id, ruby_line)
  shell_cmd = "/rails/bin/rails runner #{ruby_line.inspect}"
  out, err, status = Open3.capture3(FLY_BIN, "machine", "exec", machine_id, "-a", FLY_APP, shell_cmd)
  raise "runner failed: #{err.lines.last(8).join}" unless status.success?

  body = out.strip.lines.reject { |l| l.start_with?("Exit code:") || l.start_with?("Connecting to") }.join("\n").strip
  raise "runner empty: #{err}" if body.empty?

  body
end

def fly_logs_sample(pattern, limit: 15)
  out, status = Open3.capture2(FLY_BIN, "logs", "-a", FLY_APP, "--no-tail")
  return { error: "fly logs failed" } unless status.success?

  hits = out.lines.select { |l| l.match?(pattern) }.last(limit).map(&:strip)
  { pattern: pattern.source, count: hits.size, sample: hits }
end

RUBY_PROBE = <<~RUBY.gsub(/\s+/, " ").strip
  require 'json';
  def probe(uuid)
    p = Payment.find(uuid);
    d = p.provider_data.is_a?(Hash) ? p.provider_data : {};
    logs = PaymentStatusLog.where(payment_id: p.id).order(:created_at).map do |l|
      pr = l.provider_response.is_a?(Hash) ? l.provider_response : {};
      { at: l.created_at&.utc&.iso8601, source: l.source, note: l.note, status_to: l.status_to, rebill_id: pr['RebillId'], pan: pr['Pan'] || pr['MaskedPan'], card_id: pr['CardId'], response_keys: pr.keys.sort }
    end;
    gs = p.provider_payment_id.present? ? Payments::TbankAdapter.new.get_payment_state(payment_id: p.provider_payment_id) : nil;
    gs_slice = gs.is_a?(Hash) ? gs.slice('Status','PaymentId','Pan','MaskedPan','RebillId','CardId','ErrorCode') : gs;
    fa = logs.any? { |x| x[:note].to_s.include?('FinishAuthorize') };
    {
      payment_uuid: p.id, order_id: p.order_id, created_at: p.created_at&.utc&.iso8601, status: p.status, method: p.method, provider: p.provider,
      provider_payment_id: p.provider_payment_id, amount: p.amount&.to_s, customer_email: p.order.customer&.email,
      save_card_intent: d['save_card'], provider_data_keys: d.keys.sort, provider_data: d, status_logs: logs,
      finish_authorize_note: fa, webhook_logs: logs.select { |x| x[:source] == 'callback' }, get_state_now: gs_slice,
      saved_cards_count: MobilePaymentMethod.where(customer_id: p.order.customer_id, payment_type: 'card').count,
      saved_cards: MobilePaymentMethod.where(customer_id: p.order.customer_id, payment_type: 'card').map { |m| { card_masked: m.card_masked, card_token_prefix: m.card_token.to_s[0, 8], is_default: m.is_default, created_at: m.created_at&.utc&.iso8601 } },
      init_recurrent_inferred: (d['save_card'] == true && fa) ? 'Recurrent=Y expected (NewCardPaymentService init_payment recurrent: save_card); Init payload not stored in DB' : 'unknown_or_not_new_card'
    }
  end;
  puts JSON.generate({ target: probe(#{PAYMENT_UUID.inspect}), control: probe(#{CONTROL_UUID.inspect}) })
RUBY

FileUtils.mkdir_p(File.dirname(OUT))
machine_id = fly_machine_id
probe = JSON.parse(fly_runner(machine_id, RUBY_PROBE))

target = probe["target"]
control = probe["control"]

def present_val?(val)
  !val.nil? && val != ""
end

fa_first = (target["status_logs"] || []).find { |l| l["note"].to_s.include?("FinishAuthorize") }
delayed_confirmed = (target["webhook_logs"] || []).select { |l| l["note"].to_s.include?("CONFIRMED") && l["note"] != "FinishAuthorize CONFIRMED" }
delayed_with_rebill = delayed_confirmed.select { |l| present_val?(l["rebill_id"]) }

logs_target = fly_logs_sample(/#{TBANK_PAYMENT_ID}|#{target['order_id']}|#{PAYMENT_UUID}/i)
logs_rebill = fly_logs_sample(/RebillId.*#{TBANK_PAYMENT_ID}|OrderId.*#{target['order_id']}/i)

webhook_rebills = (target["webhook_logs"] || []).map { |l| l["rebill_id"] }.compact
fa_rebill = fa_first&.dig("rebill_id")
fa_rebill_at_incident = fa_first && !present_val?(fa_first["rebill_id"])
gs_rebill = target.dig("get_state_now", "RebillId")
provider_rebill = target.dig("provider_data", "RebillId")

root_cause = if fa_rebill_at_incident && delayed_with_rebill.any?
               "OUR_FA_WITHOUT_REBILL_DELAYED_WEBHOOK_LATE"
elsif fa_rebill_at_incident && !present_val?(provider_rebill)
               "OUR_FA_WITHOUT_REBILL_GETSTATE_NO_RETRY"
elsif present_val?(provider_rebill) && !present_val?(fa_rebill)
               "OUR_FA_WITHOUT_REBILL_LATER_WEBHOOK_MERGED"
elsif present_val?(fa_rebill) || present_val?(gs_rebill) || webhook_rebills.any?
               "REBILL_PRESENT_SHOULD_HAVE_PERSISTED"
elsif target["save_card_intent"] == true && target["finish_authorize_note"]
               "TBANK_NO_REBILL_AFTER_SAVE_CARD_NEW_CARD"
else
               "NOT_NEW_CARD_OR_SAVE_OFF"
end

fix_plan = case root_cause
when "OUR_FA_WITHOUT_REBILL_DELAYED_WEBHOOK_LATE", "OUR_FA_WITHOUT_REBILL_GETSTATE_NO_RETRY", "OUR_FA_WITHOUT_REBILL_LATER_WEBHOOK_MERGED"
             [
               "Retry GetState 3–5× с паузой после FA CONFIRMED без RebillId (NewCardPaymentService#settle_confirmed → TbankPaymentSync)",
               "Background job: отложенный sync если save_card && succeeded && RebillId blank через 30s/2m/5m",
               "TbankCallbackJob уже persist на delayed CONFIRMED+RebillId — проверить idempotent upsert *8782",
               "E2E Fly: новая карта видна в 8925 в течение минуты после оплаты (не на следующий день)"
             ]
when "REBILL_PRESENT_SHOULD_HAVE_PERSISTED"
             [ "Audit SavedCardStore / allowed_for? / persist errors for payment #{PAYMENT_UUID}" ]
else
             [ "Уточнить flow: one_click vs new_card для #{PAYMENT_UUID}" ]
end

report = {
  date: DATE,
  phase: "3.2_root_cause",
  fly_app: FLY_APP,
  machine_id: machine_id,
  target_tbank_payment_id: TBANK_PAYMENT_ID,
  target_payment_uuid: PAYMENT_UUID,
  control_payment_uuid: CONTROL_UUID,
  target: target,
  control: control,
  comparison: {
    control_has_pan: present_val?(control.dig("provider_data", "Pan")),
    control_has_rebill: present_val?(control.dig("provider_data", "RebillId")),
    target_has_pan: present_val?(target.dig("provider_data", "Pan")),
    target_has_rebill: present_val?(target.dig("provider_data", "RebillId"))
  },
  init_recurrent: {
    inferred: target["init_recurrent_inferred"],
    save_card_intent: target["save_card_intent"],
    new_card_flow: target["finish_authorize_note"],
    recurrent_in_init: "Y expected when save_card=true (TbankAdapter#init_payment recurrent: true); Init body not logged in DB"
  },
  timeline_at_incident: {
    finish_authorize_at: fa_first&.dig("at"),
    finish_authorize_rebill_id: fa_first&.dig("rebill_id"),
    finish_authorize_pan: fa_first&.dig("pan"),
    finish_authorize_keys: fa_first&.dig("response_keys"),
    customer_visible_gap: "13:23 same day — карта *8782 не в списке; RebillId пришёл только #{delayed_with_rebill.first&.dig('at') || 'later'}"
  },
  delayed_webhooks: delayed_with_rebill,
  finish_authorize: {
    first_callback: fa_first,
    stored_in_provider_data_now: target["provider_data"],
    rebill_in_provider_data_now: provider_rebill
  },
  webhook: {
    callback_log_count: (target["webhook_logs"] || []).size,
    rebill_ids_in_callbacks: webhook_rebills
  },
  get_state_now: target["get_state_now"],
  fly_logs: { payment_id: logs_target, rebill: logs_rebill },
  root_cause: root_cause,
  root_cause_plain: case root_cause
                    when "OUR_FA_WITHOUT_REBILL_DELAYED_WEBHOOK_LATE", "OUR_FA_WITHOUT_REBILL_LATER_WEBHOOK_MERGED"
                    "Наш баг: FA 09:56 без RebillId/Pan → settle + однократный GetState не дожали; банк прислал RebillId *8782 только на следующий день. Init Recurrent=Y (ожидаем). Фикс: retry GetState + delayed sync."
                    when "OUR_FA_WITHOUT_REBILL_GETSTATE_NO_RETRY"
                    "Наш баг: FA без RebillId, GetState не вернул RebillId, retry не было."
                    when "TBANK_NO_REBILL_AFTER_SAVE_CARD_NEW_CARD"
                    "Банк не выдал RebillId ни в FA, ни webhook, ни GetState при save_card ON."
                    else
                    root_cause
                    end,
  fix_plan: fix_plan
}

File.write(OUT, JSON.pretty_generate(report))
puts "Wrote #{OUT}"
puts "root_cause: #{root_cause}"
puts target["init_recurrent_inferred"]
puts "FA@incident RebillId: #{fa_first&.dig('rebill_id').inspect} | provider_data now: #{provider_rebill.inspect} | delayed: #{delayed_with_rebill.size}"
