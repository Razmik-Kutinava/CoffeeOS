#!/usr/bin/env ruby
# frozen_string_literal: true

# Прогон 10 — curl smoke на Fly (витрина, cash/card, stress, kiosk).
# Usage:
#   ruby bin/prog10_fly_smoke.rb
#   TENANTS=uuid1,uuid2 DEVICE_TOKEN=... ruby bin/prog10_fly_smoke.rb
#
# Секреты не коммитить. См. docs/operations/milestones/veha_2/FLUTTER_API.md

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
DEFAULT_TENANTS = [
  "2fdee1ac-4674-41ee-b89e-87b45643f789", # Demo A
  "655aaccb-004a-4bb9-a50a-ce618854dda3", # Demo B
  "d8e287c5-5524-423c-8e5a-605570c69517"  # Smoke QA6
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

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?
  key
end

def order_flow(tenant_id, key, payment_method, label)
  jar = "/tmp/prog10-#{label}-#{tenant_id[0, 8]}.cookies"
  File.delete(jar) if File.exist?(jar)
  curl("-c", jar, "#{BASE}/shop?tenant_id=#{tenant_id}", "-o", "/dev/null")
  products = JSON.parse(curl("#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}"))
  pid = products.dig("data", 0, "id")
  return { ok: false, error: "no products" } if pid.nil?

  curl("-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json)
  phone = format("+7905%07d", Random.rand(10_000_000))
  raw = curl("-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { name: "Prog10 #{label}", phone: phone, payment_method: payment_method }.to_json)
  body = JSON.parse(raw)
  status = body["status"] || body.dig("data", "status") || body["error"]
  url = body["payment_url"] || body.dig("data", "payment_url")
  { ok: %w[accepted pending_payment].include?(status.to_s), status: status, payment_url: url ? "present" : nil }
end

report = { base: BASE, at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), up: nil, tenants: [], stress: [], kiosk: nil }

report[:up] = curl_code("#{BASE}/up")
key = shop_key(DEFAULT_TENANTS.first)
report[:shop_api_key_len] = key.length

tenants = ENV.fetch("TENANTS", DEFAULT_TENANTS.join(",")).split(",").map(&:strip).reject(&:empty?)
tenants.each do |tid|
  code = curl_code("#{BASE}/shop?tenant_id=#{tid}")
  products_n = JSON.parse(curl("#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{key}")).dig("data")&.length
  cash = order_flow(tid, key, "cash", "cash")
  card = order_flow(tid, key, "card", "card")
  report[:tenants] << {
    tenant_id: tid,
    shop_http: code,
    products: products_n,
    cash: cash,
    card: card
  }
end

6.times do |i|
  tid = i.even? ? tenants[0] : (tenants[1] || tenants[0])
  r = order_flow(tid, key, "cash", "stress#{i}")
  report[:stress] << r.merge(tenant_id: tid)
  sleep 3
end

token = ENV["DEVICE_TOKEN"].to_s
if token.empty?
  report[:kiosk] = { skip: "no DEVICE_TOKEN" }
else
  auth = JSON.parse(curl("-X", "POST", "#{BASE}/kiosk/api/auth", "-H", "X-Device-Token: #{token}"))
  kt = auth["tenant_id"]
  report[:kiosk] = { tenant_id: kt, order: order_flow(kt, key, "cash", "kiosk") }
end

puts JSON.pretty_generate(report)

failed = report[:up] != "200" ||
  report[:tenants].any? { |t| t[:shop_http] != "200" || !t[:cash][:ok] } ||
  report[:stress].any? { |s| !s[:ok] }
exit(failed ? 1 : 0)
