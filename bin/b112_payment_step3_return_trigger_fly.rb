#!/usr/bin/env ruby
# frozen_string_literal: true

# Trigger T-Bank callback on Fly for step3 poll scenario.
#   ruby bin/b112_payment_step3_return_trigger_fly.rb ORDER_ID PAYMENT_ID

require "json"
require "open3"
require "securerandom"

FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
ORDER_ID = ARGV[0] or abort("usage: ORDER_ID PAYMENT_ID")
PAYMENT_ID = ARGV[1] or abort("usage: ORDER_ID PAYMENT_ID")

def load_fly_token!
  return if ENV["FLY_API_TOKEN"] && !ENV["FLY_API_TOKEN"].empty?

  cfg = File.expand_path("~/.fly/config.yml")
  return unless File.exist?(cfg)

  token = File.read(cfg)[/access_token:\s*(.+)/, 1]&.strip
  ENV["FLY_API_TOKEN"] = token if token && !token.empty?
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  machines.find { |m| m["state"] == "started" }&.dig("id") || machines.first&.dig("id") || raise("no fly machine")
end

load_fly_token!

ruby = <<~RUBY
  order = Order.find(#{ORDER_ID.inspect});
  pay = order.payments.order(created_at: :desc).first;
  pid = #{PAYMENT_ID.inspect}.presence || pay.provider_payment_id;
  payload = {
    "TerminalKey" => ENV.fetch("TBANK_TERMINAL_KEY"),
    "OrderId" => order.id.to_s,
    "PaymentId" => pid,
    "Status" => "CONFIRMED",
    "Amount" => (order.final_amount * 100).to_i,
    "RebillId" => "mcp-rebill-#{SecureRandom.hex(4)}",
    "Pan" => "430000******0888"
  };
  payload["Token"] = Payments::TbankAdapter.new.build_token(payload);
  Payments::TbankCallbackJob.perform_now(payload);
  order.reload;
  pay.reload;
  puts JSON.generate(order_status: order.status, payment_status: pay.status)
RUBY

out, err, status = Open3.capture3(
  FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP,
  "/rails/bin/rails runner #{ruby.gsub(/\s+/, ' ').strip.inspect}"
)
abort(err) unless status.success?

json_line = [out, err].join.lines.map(&:strip).reverse.find { |l| l.start_with?("{") && l.include?("order_status") }
puts json_line || [out, err].join
