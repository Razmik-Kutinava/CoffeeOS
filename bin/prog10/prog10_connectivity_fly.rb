#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../support/shop_api_key"

# Блок 11 CON-02: PTS на Fly — одна цена на demo-a, другая на demo-b (тот же product_id).
# Usage: ruby bin/prog10/prog10_connectivity_fly.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/connectivity/prog10_connectivity_con02_fly.json")

DEMO_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
DEMO_B = "655aaccb-004a-4bb9-a50a-ce618854dda3"

def curl_json(*args)
  raw, ok = Open3.capture2("curl", "-sS", *args)
  raise "curl failed" unless ok.success?

  JSON.parse(raw)
end

def shop_key(_tenant_id = nil)
  resolve_shop_api_key(fly_env: (respond_to?(:fly_env, true) ? method(:fly_env) : nil))
end

def first_product_price(tenant_id, api_key)
  cats = curl_json(
    "#{BASE}/shop/api/categories",
    "-H", "X-Shop-Tenant: #{tenant_id}",
    "-H", "X-Shop-Api-Key: #{api_key}"
  )
  data = cats["data"] || cats
  product = data.flat_map { |c| c["products"] || [] }.find { |p| p["id"] }
  raise "no product" unless product

  [ product["id"], product["price"].to_f ]
end

api_key = shop_key(DEMO_A)
pid_a, price_a = first_product_price(DEMO_A, api_key)
pid_b, price_b = first_product_price(DEMO_B, api_key)

same_product = pid_a == pid_b
prices_differ = price_a != price_b

detail_b = curl_json(
  "#{BASE}/shop/api/products/#{pid_a}",
  "-H", "X-Shop-Tenant: #{DEMO_B}",
  "-H", "X-Shop-Api-Key: #{api_key}"
)
price_b_direct = detail_b["price"].to_f

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  note: "CON-02: PTS per tenant on Fly (demo-a vs demo-b)",
  product_id: pid_a,
  demo_a: { tenant_id: DEMO_A, price: price_a },
  demo_b: { tenant_id: DEMO_B, price: price_b, price_via_product_id: price_b_direct },
  same_product_id: same_product,
  prices_differ: prices_differ,
  pass: same_product && prices_differ && price_b_direct == price_b
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)
exit(report[:pass] ? 0 : 1)
