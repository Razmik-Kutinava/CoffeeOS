#!/usr/bin/env ruby
# frozen_string_literal: true

# Блок 10: витрина — curl API (5 точек): меню, корзина, заказ cash, история (SHP-09 API).
# Usage:
#   ruby bin/prog10_shop_vitrina.rb
#   OUT=docs/operations/milestones/veha_2/artifacts/prog10/shop/prog10_shop_vitrina_curl.json ruby bin/prog10_shop_vitrina.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
ORDER_DELAY = ENV.fetch("ORDER_DELAY_SEC", "5").to_f
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/shop/prog10_shop_vitrina_curl.json")

# 5 точек прогона 10 (не 9): demo A/B + по 2 из Alpha/Beta
POINTS = [
  { slug: "demo-a", tenant_id: "2fdee1ac-4674-41ee-b89e-87b45643f789" },
  { slug: "demo-b", tenant_id: "655aaccb-004a-4bb9-a50a-ce618854dda3" },
  { slug: "alpha-p1", tenant_id: "1c064640-4301-4435-8ded-c92fb075e9cc" },
  { slug: "alpha-p2", tenant_id: "edf8a0a9-38e7-4049-b9c6-3e08c6c23a76" },
  { slug: "beta-p1", tenant_id: "03a4d457-e16f-4998-b764-69b3de083732" }
].freeze

def run_curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(6).join(' ')}" unless status.success?

  out
end

def pause
  sleep ORDER_DELAY if ORDER_DELAY.positive?
end

def shop_key(tenant_id)
  html = run_curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?

  key
end

suffix = Time.now.utc.strftime("%m%d%H%M")
shop_key_cache = shop_key(POINTS.first[:tenant_id])

results = POINTS.map do |point|
  tid = point[:tenant_id]
  jar = "/tmp/prog10-sh10-#{point[:slug]}.cookies"
  File.delete(jar) if File.exist?(jar)

  row = { slug: point[:slug], tenant_id: tid, menu: nil, cart: nil, checkout: nil, shp09_history: nil, pass: false }

  run_curl("-c", jar, "#{BASE}/shop?tenant_id=#{tid}", "-o", "/dev/null")
  products = JSON.parse(
    run_curl("#{BASE}/shop/api/products", "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{shop_key_cache}")
  )
  cats = JSON.parse(
    run_curl("#{BASE}/shop/api/categories", "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{shop_key_cache}")
  )
  pid = products.dig("data", 0, "id")
  n_prod = products.dig("data")&.length.to_i
  n_cat = cats.is_a?(Array) ? cats.length : cats.dig("data")&.length.to_i
  row[:menu] = { ok: n_prod.positive?, products: n_prod, categories: n_cat }
  next row unless row[:menu][:ok]

  pause
  run_curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{shop_key_cache}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
  )
  cart = JSON.parse(
    run_curl("#{BASE}/shop/api/cart", "-b", jar, "-c", jar,
      "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{shop_key_cache}")
  )
  items_n = cart.dig("items")&.length.to_i
  row[:cart] = { ok: items_n.positive?, items: items_n, total: cart["total"] }

  pause
  phone = format("+7906%07d", rand(10_000_000))
  label = "SHP10-#{point[:slug]}-#{suffix}"
  order_raw = run_curl(
    "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{shop_key_cache}",
    "-H", "Content-Type: application/json",
    "--data-binary", { name: label, phone: phone, payment_method: "cash" }.to_json
  )
  order = JSON.parse(order_raw)
  oid = order["order_id"]
  row[:checkout] = {
    ok: !oid.nil? && order["status"] == "accepted",
    order_id: oid,
    status: order["status"]
  }

  pause
  hist_raw = run_curl(
    "#{BASE}/shop/api/orders/history?today=1", "-b", jar, "-c", jar,
    "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{shop_key_cache}"
  )
  hist = JSON.parse(hist_raw)
  hist_list = hist.is_a?(Array) ? hist : []
  found = hist_list.any? { |o| o["id"].to_s == oid.to_s }
  row[:shp09_history] = { ok: found, count: hist_list.length, order_id: oid }

  row[:pass] = row[:menu][:ok] && row[:cart][:ok] && row[:checkout][:ok] && row[:shp09_history][:ok]
  row
end

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  note: "block 10: shop vitrina curl 5pt — menu/cart/checkout/SHP-09 history API",
  points: results
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)
exit(results.all? { |r| r[:pass] } ? 0 : 1)
