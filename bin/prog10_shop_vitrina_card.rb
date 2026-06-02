#!/usr/bin/env ruby
# frozen_string_literal: true

# Блок 10 добивка: mock card checkout на 5 точках (curl).
# Usage: ruby bin/prog10_shop_vitrina_card.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
ORDER_DELAY = ENV.fetch("ORDER_DELAY_SEC", "5").to_f
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/shop/prog10_shop_vitrina_card_curl.json")

POINTS = [
  { slug: "demo-a", tenant_id: "2fdee1ac-4674-41ee-b89e-87b45643f789" },
  { slug: "demo-b", tenant_id: "655aaccb-004a-4bb9-a50a-ce618854dda3" },
  { slug: "alpha-p1", tenant_id: "1c064640-4301-4435-8ded-c92fb075e9cc" },
  { slug: "alpha-p2", tenant_id: "edf8a0a9-38e7-4049-b9c6-3e08c6c23a76" },
  { slug: "beta-p1", tenant_id: "03a4d457-e16f-4998-b764-69b3de083732" }
].freeze

def run_curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed" unless status.success?

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

shop_key = run_curl("#{BASE}/shop?tenant_id=#{POINTS.first[:tenant_id]}")
key = shop_key[/shop-api-key" content="([^"]+)/, 1]
raise "no shop-api-key" if key.nil? || key.empty?

suffix = Time.now.utc.strftime("%m%d%H%M")
results = POINTS.map do |point|
  tid = point[:tenant_id]
  jar = "/tmp/prog10-sh10-card-#{point[:slug]}.cookies"
  File.delete(jar) if File.exist?(jar)

  run_curl("-c", jar, "#{BASE}/shop?tenant_id=#{tid}", "-o", "/dev/null")
  products = JSON.parse(
    run_curl("#{BASE}/shop/api/products", "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{key}")
  )
  pid = products.dig("data", 0, "id")
  row = { slug: point[:slug], tenant_id: tid, pass: false }
  if pid.nil?
    row[:error] = "no products"
    next row
  end

  pause
  run_curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
  )
  pause
  phone = format("+7907%07d", rand(10_000_000))
  order_raw = run_curl(
    "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", {
      name: "SHP10-card-#{point[:slug]}-#{suffix}",
      phone: phone,
      payment_method: "card"
    }.to_json
  )
  order = JSON.parse(order_raw)
  row[:checkout] = {
    order_id: order["order_id"],
    status: order["status"],
    payment_url: order["payment_url"] ? "present" : nil
  }
  row[:pass] =
    !order["order_id"].to_s.empty? &&
    order["status"] == "pending_payment" &&
    !order["payment_url"].to_s.empty?
  row
end

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  note: "block 10: mock card checkout curl 5pt",
  points: results
}
File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)
exit(results.all? { |r| r[:pass] } ? 0 : 1)
