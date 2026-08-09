#!/usr/bin/env ruby
# frozen_string_literal: true

# Прогон 10 — полный curl smoke на Fly.
# Usage:
#   ruby bin/prog10/prog10_fly_smoke.rb
#   TENANTS=uuid1,uuid2 ORDER_DELAY_SEC=7 ruby bin/prog10/prog10_fly_smoke.rb
#   KIOSK_TOKENS_FILE=path/to/tokens.json ruby bin/prog10/prog10_fly_smoke.rb
#
# tokens.json: { "tenant-uuid": "device_token_hex", ... }
# Секреты не коммитить.

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
ORDER_DELAY = ENV.fetch("ORDER_DELAY_SEC", "7").to_f

# 3 org × 3 точки (без smoke QA6)
PROG10_NINE = %w[
  2fdee1ac-4674-41ee-b89e-87b45643f789
  655aaccb-004a-4bb9-a50a-ce618854dda3
  d47165db-81c9-4e9d-bc50-e37fe610d86c
  1c064640-4301-4435-8ded-c92fb075e9cc
  edf8a0a9-38e7-4049-b9c6-3e08c6c23a76
  d29fcf3a-da72-4a95-9683-9cfa71a2d865
  03a4d457-e16f-4998-b764-69b3de083732
  628a937b-f4e2-43b7-bd7f-9fa44f031460
  b57c2a88-91a5-481e-b44f-29e29c77cfb5
].freeze

def curl(*args)
  out, status = Open3.capture2("curl", "-s", *args)
  raise "curl failed: #{args.first(3).join(' ')}" unless status
  out
end

def curl_code(*args)
  out, status = Open3.capture2("curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", *args)
  raise "curl failed" unless status
  out.strip
end

def pause
  sleep ORDER_DELAY if ORDER_DELAY.positive?
end

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?
  key
end

def order_ok?(body)
  status = body["status"] || body.dig("data", "status")
  return true if %w[accepted pending_payment].include?(status.to_s)

  err = body["error"]
  return false if err.nil?

  err.is_a?(Hash) ? err["code"] != "RATE_LIMIT_EXCEEDED" : true
end

def parse_order(raw)
  body = JSON.parse(raw)
  status = body["status"] || body.dig("data", "status") || body["error"]
  url = body["payment_url"] || body.dig("data", "payment_url")
  {
    ok: order_ok?(body),
    status: status,
    payment_url: url ? "present" : nil
  }
end

def order_flow(tenant_id, key, payment_method, label)
  jar = "/tmp/prog10-#{label}-#{tenant_id[0, 8]}.cookies"
  File.delete(jar) if File.exist?(jar)
  curl("-c", jar, "#{BASE}/shop?tenant_id=#{tenant_id}", "-o", "/dev/null")
  products = JSON.parse(curl("#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}"))
  pid = products.dig("data", 0, "id")
  return { ok: false, error: "no products", skipped: true } if pid.nil?

  curl("-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json)
  pause
  phone = format("+7905%07d", Random.rand(10_000_000))
  raw = curl("-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { name: "Prog10 #{label}", phone: phone, payment_method: payment_method }.to_json)
  parse_order(raw)
end

def kiosk_order(tenant_id, device_token, key)
  auth = JSON.parse(curl("-X", "POST", "#{BASE}/kiosk/api/auth", "-H", "X-Device-Token: #{device_token}"))
  return { ok: false, error: "auth failed", auth: auth } unless auth["tenant_id"]

  pause
  cash = order_flow(tenant_id, key, "cash", "kiosk-cash")
  pause
  card = order_flow(tenant_id, key, "card", "kiosk-card")
  { cash: cash, card: card }
end

def load_kiosk_tokens
  path = ENV["KIOSK_TOKENS_FILE"].to_s
  return {} if path.empty? || !File.exist?(path)

  JSON.parse(File.read(path))
end

report = {
  base: BASE,
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  order_delay_sec: ORDER_DELAY,
  up: nil,
  tenants: [],
  stress: [],
  kiosk: []
}

report[:up] = curl_code("#{BASE}/up")
tenants = ENV.fetch("TENANTS", PROG10_NINE.join(",")).split(",").map(&:strip).reject(&:empty?)
key = shop_key(tenants.first)
report[:shop_api_key_len] = key.length

unless ENV["SKIP_TENANTS"] == "1"
tenants.each do |tid|
  code = curl_code("#{BASE}/shop?tenant_id=#{tid}")
  products_n = JSON.parse(curl("#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{key}")).dig("data")&.length
  cash = order_flow(tid, key, "cash", "cash")
  pause
  card = order_flow(tid, key, "card", "card")
  pause
  report[:tenants] << {
    tenant_id: tid,
    shop_http: code,
    products: products_n,
    cash: cash,
    card: card
  }
end

end

unless ENV["SKIP_STRESS"] == "1"
stress_rounds = ENV.fetch("STRESS_ROUNDS", "8").to_i
stress_offset = ENV.fetch("STRESS_OFFSET", "0").to_i
stress_rounds.times do |i|
  idx = (i + stress_offset) % tenants.length
  tid = tenants[idx]
  r = order_flow(tid, key, "cash", "stress#{stress_offset}-#{i}")
  report[:stress] << r.merge(tenant_id: tid, round: i + 1, wave: stress_offset.zero? ? 1 : 2)
  pause
end
end

kiosk_tokens = load_kiosk_tokens
if kiosk_tokens.empty?
  report[:kiosk] = { skip: "no KIOSK_TOKENS_FILE" }
else
  kiosk_tokens.each do |tid, token|
    report[:kiosk] << { tenant_id: tid, token_prefix: token.to_s[0, 8], order: kiosk_order(tid, token, key) }
    pause
  end
end

out_path = ENV["OUT"]
File.write(out_path, JSON.pretty_generate(report)) if out_path && !out_path.empty?
puts JSON.pretty_generate(report)

sales_tenants = report[:tenants].reject { |t| t[:cash][:skipped] }
failed = report[:up] != "200" ||
  sales_tenants.any? { |t| t[:shop_http] != "200" || !t[:cash][:ok] || !t[:card][:ok] } ||
  report[:stress].any? { |s| !s[:ok] } ||
  (kiosk_tokens.any? && report[:kiosk].is_a?(Array) && report[:kiosk].any? do |k|
    o = k[:order]
    !o.dig(:cash, :ok) || !o.dig(:card, :ok)
  end)

exit(failed ? 1 : 0)
