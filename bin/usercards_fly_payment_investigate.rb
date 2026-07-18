#!/usr/bin/env ruby
# frozen_string_literal: true

# Разбор платежей aramfifa на Fly prod: Pan/RebillId/save_card по payment id или за сегодня.
#
#   ruby bin/usercards_fly_payment_investigate.rb
#   UC_EMAIL=other@mail.com ruby bin/usercards_fly_payment_investigate.rb

require "json"
require "open3"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
EMAIL = ENV.fetch("UC_EMAIL", "aramfifa100@gmail.com")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/usercards_save_card",
  "usercards_fly_payment_investigate_#{DATE}.json"
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
  raise "runner failed: #{err.lines.last(5).join}" unless status.success?

  line = out.strip.lines.reject { |l| l.start_with?("Exit code:") || l.start_with?("Connecting to") }.join("\n").strip
  raise "runner empty: err=#{err}" if line.empty?

  line
end

RUBY_PROBE = <<~RUBY.gsub(/\s+/, " ").strip
  require 'json';
  email = #{EMAIL.inspect};
  c = MobileCustomer.find_by(email: email);
  today = Time.current.utc.beginning_of_day;
  scope = Payment.joins(:order).where(orders: { customer_id: c&.id }).where('payments.created_at >= ?', today).order(created_at: :desc);
  payments = scope.map do |p|
    d = p.provider_data.is_a?(Hash) ? p.provider_data : {};
    {
      payment_id: p.id,
      order_id: p.order_id,
      created_at: p.created_at&.utc&.iso8601,
      status: p.status,
      provider: p.provider,
      provider_payment_id: p.provider_payment_id,
      amount: p.amount&.to_s,
      save_card: d['save_card'],
      rebill_id: d['RebillId'],
      pan: d['Pan'] || d['MaskedPan'],
      card_id: d['CardId'],
      tbank_status: d['Status']
    }
  end;
  cards = c ? MobilePaymentMethod.where(customer_id: c.id, payment_type: 'card').map { |m|
    { id: m.id, card_masked: m.card_masked, card_token: m.card_token.to_s[0, 12], is_default: m.is_default, created_at: m.created_at&.utc&.iso8601 }
  } : [];
  pans = payments.map { |x| x[:pan] }.compact.uniq;
  puts JSON.generate({
    email: email,
    customer_id: c&.id,
    payments_today: payments,
    unique_pans_today: pans,
    different_cards_today: pans.size > 1,
    saved_cards: cards
  })
RUBY

FileUtils.mkdir_p(File.dirname(OUT))
machine_id = fly_machine_id
raw = fly_runner(machine_id, RUBY_PROBE)
data = JSON.parse(raw)

report = {
  date: DATE,
  fly_app: FLY_APP,
  machine_id: machine_id,
  email: EMAIL,
  investigation: data,
  verdict: if data["payments_today"].empty? && data["saved_cards"].size >= 2
             "TWO_SAVED_CARDS_NO_PAYMENT_TODAY"
           elsif data["payments_today"].empty?
             "NO_PAYMENTS_TODAY"
           elsif data["different_cards_today"]
             "MULTIPLE_PANS_TODAY"
           elsif data["payments_today"].size >= 2 && data["unique_pans_today"].size == 1
             second = data["payments_today"].first
             if second["pan"].nil? && second["rebill_id"].nil?
               "SECOND_PAYMENT_NO_PAN_FROM_TBANK"
             else
               "MULTIPLE_PAYMENTS_SAME_PAN"
             end
           else
             "SINGLE_PAYMENT_TODAY"
           end
}

File.write(OUT, JSON.pretty_generate(report))
puts "Wrote #{OUT}"
puts "verdict: #{report[:verdict]}"
puts "payments_today: #{data['payments_today'].size}"
puts "unique_pans: #{data['unique_pans_today'].inspect}"
data["payments_today"].each do |p|
  puts "#{p['created_at']} | #{p['status']} | amount=#{p['amount']} | pan=#{p['pan'].inspect} | rebill=#{p['rebill_id'].inspect} | tbank_id=#{p['provider_payment_id']}"
end
