#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.13-S2 — prep Fly MCP: очистка корзины + product_id для add-to-cart.
#
#   ruby bin/acceptance/b113_s2_cart_popup_prep_fly.rb
#   node bin/acceptance/b113_s2_cart_popup_mcp.mjs

require "json"
require "open3"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
TENANT_ID = ENV.fetch("B113_TENANT_ID", "655aaccb-004a-4bb9-a50a-ce618854dda3")
OUT = File.join(ROOT, "tmp/b113_s2_cart_popup_prep.json")
DATE = Time.now.utc.strftime("%Y-%m-%d")

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first}" unless status.success?

  out
end

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key on #{BASE}" if key.nil? || key.empty?

  key
end

def api_json(path, key, method: "GET", body: nil)
  args = [
    "-X", method,
    "-H", "Accept: application/json",
    "-H", "Content-Type: application/json",
    "-H", "X-Shop-Api-Key: #{key}",
    "#{BASE}/shop/api#{path}",
    "-w", "\n%{http_code}"
  ]
  args += [ "-d", body.to_json ] if body
  raw = curl(*args)
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [ JSON.parse(body_raw), http ]
end

key = shop_key(TENANT_ID)
api_json("/cart?tenant_id=#{TENANT_ID}", key, method: "DELETE")

cats, http = api_json("/categories?tenant_id=#{TENANT_ID}", key)
raise "categories #{http}" unless http == 200

product = cats.dig("data", 0, "products", 0)
raise "no product in categories" unless product

prep = {
  task_id: "B1.13-S2",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  shop_url: "#{BASE}/shop?tenant_id=#{TENANT_ID}",
  product_id: product["id"],
  product_name: product["name"],
  profile_storage_key: "coffeeos:shop:guest-profile"
}

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(prep))
puts "Wrote #{OUT}"
puts "product: #{product['name']} (#{product['id']})"
