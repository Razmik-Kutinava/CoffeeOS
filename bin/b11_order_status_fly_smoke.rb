#!/usr/bin/env ruby
# frozen_string_literal: true

# Fly smoke: B1.1 экран статуса заказа (API + тайминги).
#
#   ruby bin/b11_order_status_fly_smoke.rb
#   FLY_BIN=$HOME/.fly/bin/fly ruby bin/b11_order_status_fly_smoke.rb
#
# OTP: fly machine exec + rails runner (как shop_checkout_otp_fly_multitenant.rb).

require "json"
require "open3"
require "shellwords"
require "tmpdir"
require "benchmark"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "fly")
TENANT_ID = ENV.fetch("B11_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
OUT = ENV.fetch(
  "OUT",
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b11_fly_smoke_#{Time.now.utc.strftime('%Y-%m-%d')}.json"
)
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(4).join(' ')}" unless status.success?

  out
end

def curl_json(*args)
  JSON.parse(curl(*args))
end

def curl_post_json(*args)
  raw = curl(*args, "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [JSON.parse(body_raw), http]
rescue JSON::ParserError
  [{ "raw" => body_raw }, http]
end

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?

  key
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  machine = machines.find { |m| m["state"] == "started" } || machines.first
  machine&.dig("id") || raise("no fly machine")
end

def fetch_otp_from_fly(email)
  ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
  remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote_cmd)
  combined = [out, err].join
  code = combined.scan(/\b(\d{6})\b/).last&.first
  code = nil if code == "NONE"
  code
rescue StandardError => e
  warn "[fly-otp] #{e.message}"
  nil
end

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b11-fly-#{suffix}@coffeeos.dev"
api_key = shop_key(TENANT_ID)
jar = File.join(Dir.tmpdir, "b11-fly-#{suffix}.cookies")
File.delete(jar) if File.exist?(jar)

result = {
  task: "B1_1_order_status_fly_smoke",
  date: Time.now.utc.strftime("%Y-%m-%d"),
  base: BASE,
  tenant_id: TENANT_ID,
  email: email,
  checks: [],
  status: "FAIL"
}

begin
  curl("-c", jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

  products = curl_json(
    "#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{TENANT_ID}",
    "-H", "X-Shop-Api-Key: #{api_key}"
  )
  pid = products.dig("data", 0, "id")
  raise "no product on tenant" unless pid

  send_body, send_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/send",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email }.to_json
  )
  result[:checks] << { id: "otp_send", pass: send_http == 200, http: send_http }

  code = fetch_otp_from_fly(email)
  raise "otp not fetched from fly" unless code

  verify_body, verify_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, code: code }.to_json
  )
  result[:checks] << { id: "otp_verify", pass: verify_http == 200 && verify_body["verified"], http: verify_http }

  curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
  )

  order_ms = nil
  order_body = nil
  order_http = nil
  order_ms = Benchmark.realtime do
    order_body, order_http = curl_post_json(
      "-X", "POST", "#{BASE}/shop/api/orders",
      "-c", jar, "-b", jar,
      "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
      "-H", "Content-Type: application/json",
      "--data-binary", { email: email, name: "B11 Fly", payment_method: "cash" }.to_json
    )
  end
  order_id = order_body["order_id"]
  result[:checks] << {
    id: "create_order",
    pass: order_http == 200 && order_id.present? && order_body["status"] == "accepted",
    http: order_http,
    order_id: order_id,
    order_create_ms: (order_ms * 1000).round
  }

  show_body = curl_json(
    "#{BASE}/shop/api/orders/#{order_id}",
    "-b", jar, "-c", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}"
  )
  cancel_route_probe = curl(
    "-X", "POST", "#{BASE}/shop/api/orders/#{order_id}/cancel",
    "-b", jar, "-c", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "-w", "\n%{http_code}"
  )
  cancel_lines = cancel_route_probe.lines
  cancel_http = cancel_lines.last.to_s.strip.to_i
  cancel_body = JSON.parse(cancel_lines[0..-2].join) rescue { "raw" => cancel_lines[0..-2].join }

  result[:checks] << {
    id: "order_show_fields",
    pass: show_body["can_cancel"] == true && show_body["order_number"].present? && show_body.dig("tenant", "name").present?,
    body_keys: show_body.keys
  }
  result[:checks] << {
    id: "guest_cancel",
    pass: cancel_http == 200 && cancel_body["status"] == "cancelled" && cancel_body["cancelled_by"] == "guest",
    http: cancel_http
  }

  # cancel endpoint missing on old deploy → 404
  if cancel_http == 404
    result[:deploy_note] = "POST /shop/api/orders/:id/cancel not on Fly — нужен deploy develop"
  end

  result[:status] = result[:checks].all? { |c| c[:pass] } ? "PASS" : "FAIL"
rescue StandardError => e
  result[:error] = "#{e.class}: #{e.message}"
  result[:status] = "FAIL"
ensure
  File.write(OUT, JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
  puts "written #{OUT}"
end
