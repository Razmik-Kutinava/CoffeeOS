#!/usr/bin/env ruby
# frozen_string_literal: true

# SHP-03 / SHP-05: /shop без tenant_id в URL + API без tenant.
# Usage: ruby bin/prog10/prog10_shop_shp03.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/shop/prog10_shop_shp03.json")

def run_curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed" unless status.success?

  out
end

def curl_code(url)
  out, status = Open3.capture2("curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", url)
  raise "curl failed" unless status

  out.strip
end

html = run_curl("#{BASE}/shop")
shop_http = curl_code("#{BASE}/shop")
sec07_no_meta_key = !html.include?("shop-api-key")
has_products_hint = html.include?("₽") || html.include?("Пока нет товаров")
has_tenant_meta = html[/shop-tenant-id" content="([^"]+)"/, 1]
has_banner = html.match?(/tenant|точк|SHOP_DEFAULT|выбер/i)

cats_code = curl_code("#{BASE}/shop/api/categories")
cats_body = run_curl("#{BASE}/shop/api/categories")

# SHP-05: без tenant в API — 404 (строгий dev) или 200 (fallback на Fly) — не 500
api_no_tenant_not_500 = cats_code != "500"
api_no_tenant_ok = %w[404 200].include?(cats_code)

# Страница /shop без ?tenant_id: 200 и fallback-тенант в meta или каталог — не 500
page_ok = shop_http == "200" && (!has_tenant_meta.to_s.empty? || has_banner || has_products_hint)

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  scenario: "SHP-03 + SHP-05",
  sec07: {
    no_meta_key: sec07_no_meta_key,
    pass: sec07_no_meta_key
  },
  shp03: {
    shop_http: shop_http,
    has_tenant_meta: has_tenant_meta,
    has_catalog_hint: has_products_hint,
    has_banner_hint: !!has_banner,
    pass: page_ok
  },
  shp05: {
    categories_http: cats_code,
    body_preview: cats_body[0, 120],
    pass: api_no_tenant_ok && api_no_tenant_not_500,
    note: cats_code == "200" ? "Fly fallback tenant (не 404, но ок)" : nil
  },
  pass: page_ok && api_no_tenant_ok && api_no_tenant_not_500 && sec07_no_meta_key
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)
exit(report[:pass] ? 0 : 1)
