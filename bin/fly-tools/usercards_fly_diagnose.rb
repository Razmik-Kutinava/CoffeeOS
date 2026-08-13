#!/usr/bin/env ruby
# frozen_string_literal: true

# UserCards Фаза 0 — read-only диагностика Fly prod.
#
#   ruby bin/fly-tools/usercards_fly_diagnose.rb
#
# → docs/operations/milestones/veha_2/artifacts/usercards_save_card/usercards_fly_diagnose_YYYY-MM-DD.json

require "json"
require "open3"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/usercards_save_card/usercards_fly_diagnose_#{DATE}.json")

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed (#{FLY_BIN} auth?)" unless status.success?

  machines = JSON.parse(out)
  web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
  web ||= machines.find { |m| m["state"] == "started" }
  web&.dig("id") || raise("no started fly machine")
end

def fly_worker_state
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  return "unknown" unless status.success?

  machines = JSON.parse(out)
  worker = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "worker" }
  worker ? worker["state"] : "missing"
end

def fly_runner(machine_id, ruby_line)
  shell_cmd = "/rails/bin/rails runner #{ruby_line.inspect}"
  out, err, status = Open3.capture3(FLY_BIN, "machine", "exec", machine_id, "-a", FLY_APP, shell_cmd)
  unless status.success?
    warn "runner failed (#{ruby_line[0..80]}…): #{err.lines.last(3).join}"
    return nil
  end

  line = out.strip.lines.reject { |l| l.start_with?("Exit code:") || l.start_with?("Connecting to") }.last&.strip
  return line if line && !line.start_with?("Exit code:")

  warn "runner empty/bad (#{ruby_line[0..80]}…): out=#{out.inspect} err=#{err.lines.last(3).join}"
  nil
end

def fly_runner_json(machine_id, ruby_line)
  raw = fly_runner(machine_id, ruby_line)
  return [] if raw.nil? || raw.empty?

  JSON.parse(raw)
rescue JSON::ParserError => e
  warn "JSON parse failed: #{e.message} raw=#{raw.inspect}"
  { "parse_error" => e.message, "raw" => raw }
end

def probe_bundle
  html = Open3.capture2("curl", "-sS", "https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789").first
  bundle = html[%r{/vite/assets/application-[A-Za-z0-9_-]+\.js}, 0]
  js_path = bundle || "/vite/assets/application-D1E05YN_.js"
  js = Open3.capture2("curl", "-sS", "https://coffeeos.fly.dev#{js_path}").first
  {
    application_js: js_path,
    shop_checkout_pay_event: js.include?("shop:checkout-pay"),
    prog24: js.include?("prog24"),
    inline_pay_string: js.include?("Оплатить →"),
    payment_method_string: js.include?("Способ оплаты")
  }
end

def fly_logs_grep(pattern, limit: 80)
  out, status = Open3.capture2(FLY_BIN, "logs", "-a", FLY_APP, "--no-tail")
  return { error: "fly logs failed" } unless status.success?

  hits = out.lines.select { |l| l.match?(pattern) }.last(limit)
  { pattern: pattern.source, count: hits.size, sample: hits.last(10).map(&:strip) }
rescue StandardError => e
  { error: e.message }
end

def fly_release
  out, status = Open3.capture2(FLY_BIN, "releases", "-a", FLY_APP, "--json")
  return {} unless status.success?

  rel = JSON.parse(out).first
  {
    version: rel&.dig("Version"),
    status: rel&.dig("Status"),
    image: rel&.dig("ImageRef"),
    created_at: rel&.dig("CreatedAt")
  }
end

FileUtils.mkdir_p(File.dirname(OUT))
machine_id = fly_machine_id

db = {
  env: {
    shop_simulate_payment: fly_runner(machine_id, "puts ENV.fetch('SHOP_SIMULATE_PAYMENT', 'nil')"),
    tbank_terminal_set: fly_runner(machine_id, "puts ENV['TBANK_TERMINAL_KEY'].to_s.present?"),
    tbank_rsa_set: fly_runner(machine_id, "puts ENV['TBANK_RSA_PUBLIC_KEY'].to_s.present?")
  },
  counts: {
    mobile_payment_methods_card: fly_runner(machine_id, "puts MobilePaymentMethod.where(payment_type: 'card').count").to_i,
    mobile_customers: fly_runner(machine_id, "puts MobileCustomer.count").to_i,
    payments_tbank_30d: fly_runner(machine_id, "puts Payment.where(provider: 'tbank').where('created_at > ?', 30.days.ago).count").to_i,
    payments_tbank_succeeded_30d: fly_runner(machine_id, "puts Payment.where(provider: 'tbank', status: :succeeded).where('created_at > ?', 30.days.ago).count").to_i,
    payments_shop_30d: fly_runner(machine_id, "puts Payment.where(provider: 'shop').where('created_at > ?', 30.days.ago).count").to_i
  },
  gmail_customers_sample: fly_runner_json(
    machine_id,
    "require 'json'; rows=MobileCustomer.where('email ILIKE ?','%gmail.com%').order(updated_at: :desc).limit(5).pluck(:email,:first_name,:updated_at); puts JSON.generate(rows.map{|e,n,t|{email:e,name:n,updated_at:t&.iso8601}})"
  ),
  recent_cards: fly_runner_json(
    machine_id,
    "require 'json'; puts JSON.generate(MobilePaymentMethod.includes(:customer).where(payment_type:'card').order(last_used_at: :desc, created_at: :desc).limit(5).map{|c|{id:c.id,email:c.customer&.email,card_masked:c.card_masked,card_token_present:c.card_token.present?,is_active:c.is_active,is_default:c.is_default,last_used_at:c.last_used_at&.iso8601,created_at:c.created_at&.iso8601}})"
  ),
  recent_tbank_payments: fly_runner_json(
    machine_id,
    "require 'json'; puts JSON.generate(Payment.where(provider:'tbank').order(created_at: :desc).limit(5).map{|p|{id:p.id,status:p.status,save_card:(p.provider_data.is_a?(Hash)?p.provider_data['save_card']:nil),email:p.order&.customer&.email,created_at:p.created_at&.iso8601}})"
  ),
  aramfifa_cards: fly_runner_json(
    machine_id,
    "require 'json'; c=MobileCustomer.find_by(email:'aramfifa100@gmail.com'); puts JSON.generate(c ? MobilePaymentMethod.where(customer_id:c.id,payment_type:'card').map{|m|{id:m.id,card_masked:m.card_masked,is_active:m.is_active,is_default:m.is_default,last_used_at:m.last_used_at&.iso8601}} : [])"
  )
}

report = {
  date: DATE,
  phase: "0_diagnose_read_only",
  tz_reference: "docs/operations/milestones/veha_2/artifacts/usercards_save_card/screenshots/",
  customer_bug: "bug_13-23_repeat_purchase_card_missing.png — карта не в списке после оплаты с save_card ON",
  fly_app: FLY_APP,
  machine_id: machine_id,
  worker_state: fly_worker_state,
  release: fly_release,
  bundle_probe: probe_bundle,
  logs: {
    new_card: fly_logs_grep(/payments\/new_card|NewCardPayment/),
    tbank_callback: fly_logs_grep(/TbankCallback|SavedCardStore/),
    user_cards_api: fly_logs_grep(/user\/cards|UserCards/)
  },
  db: db,
  code_paths: {
    save_card_api: "POST /shop/api/payments/new_card → NewCardPaymentService (Recurrent=save_card)",
    legacy_redirect: "POST /shop/api/orders → OrderCreator#init_gateway_payment! recurrent: false",
    persist_hooks: %w[SavedCardStore NewCardPaymentService#settle TbankCallbackJob TbankPaymentSync]
  },
  root_cause_table: [
    {
      check: "0.2 mobile_payment_methods",
      result: db.dig(:counts, :mobile_payment_methods_card).zero? ? "EMPTY" : "has rows (#{db.dig(:counts, :mobile_payment_methods_card)} card)",
      implication: db.dig(:counts, :mobile_payment_methods_card).zero? ? "Пусто → GET /user/cards = [] → UI только СБП (bug_13-23)" : "Глобально карты есть; проверить aramfifa_cards per-customer"
    },
    {
      check: "0.3 payment path",
      result: db.dig(:counts, :payments_tbank_30d).zero? ? "no tbank 30d" : "tbank payments exist",
      implication: "Нет tbank → оплата не через new_card/nonPCI или другая БД"
    },
    {
      check: "0.4 webhook worker",
      result: fly_worker_state,
      implication: "worker stopped → TbankCallbackJob async не бежит"
    },
    {
      check: "0.5 SHOP_SIMULATE_PAYMENT",
      result: db.dig(:env, :shop_simulate_payment),
      implication: "1 → new_card blocked; orders simulate без RebillId"
    }
  ],
  hypotheses: [],
  next_phase: {
    phase: 1,
    actions: [
      "Network заказчика: /payments/new_card vs /orders",
      "Поднять worker если stopped",
      "Fix OrderCreator recurrent:false для card+save",
      "E2E Fly save_card → mobile_payment_methods row"
    ]
  }
}

[
  [:H1_empty_usercards, db.dig(:counts, :mobile_payment_methods_card).to_i.zero?, "critical",
   "mobile_payment_methods (card) = 0", "список карт пуст → bug_13-23"],
  [:H1b_customer_no_cards, db.dig(:aramfifa_cards).is_a?(Array) && db.dig(:aramfifa_cards).empty?, "critical",
   "aramfifa100@gmail.com — 0 saved cards", "оплата save_card=true 2026-07-15 но карта не в UserCards этого email"],
  [:H2_worker_stopped, fly_worker_state == "stopped", "high",
   "worker stopped", "webhook/async save не обрабатывается"],
  [:H3_no_tbank, db.dig(:counts, :payments_tbank_30d).to_i.zero?, "high",
   "payments tbank 30d = 0", "nonPCI new_card не использовался на prod"],
  [:H3b_save_card_without_persist, begin
     pays = db.dig(:recent_tbank_payments)
     pays.is_a?(Array) && pays.any? { |p| p["save_card"] == true } && db.dig(:aramfifa_cards).is_a?(Array) && db.dig(:aramfifa_cards).empty?
   end, "critical",
   "save_card payment succeeded but customer cards empty", "SavedCardStore/webhook/finalize не создал row"],
  [:H4_simulate, db.dig(:env, :shop_simulate_payment) == "1", "critical",
   "SHOP_SIMULATE_PAYMENT=1", "new_card reject; simulate без токена"]
].each do |id, cond, sev, finding, meaning|
  next unless cond

  report[:hypotheses] << { id: id.to_s, severity: sev, finding: finding, meaning: meaning }
end

File.write(OUT, JSON.pretty_generate(report))
puts "Wrote #{OUT}"
