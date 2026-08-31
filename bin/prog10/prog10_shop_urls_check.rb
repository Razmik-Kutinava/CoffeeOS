#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../support/shop_api_key"

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
IDS_PATH = File.expand_path("../../docs/operations/milestones/veha_2/artifacts/prog10/_index/prog10_tenant_ids.json", __dir__)
TENANTS = JSON.parse(File.read(IDS_PATH))

def curl_code(url)
  out, status = Open3.capture2("curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", url)
  raise "curl failed" unless status
  out.strip
end

def shop_ok?(tid)
  code = curl_code("#{BASE}/shop?tenant_id=#{tid}")
  key = resolve_shop_api_key(fly_env: nil)
  n = 0
  if key && !key.empty?
    products, = Open3.capture2("curl", "-s", "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{key}",
      "#{BASE}/shop/api/products")
    n = JSON.parse(products).dig("data")&.length.to_i
  end
  { shop_http: code, api_key: key ? "present" : nil, products: n }
end

results = TENANTS.map do |row|
  row.merge(shop: shop_ok?(row["tenant_id"]))
end

out = { at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), tenants: results }
path = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/smoke/prog10_shop_urls.json")
File.write(path, JSON.pretty_generate(out))
puts JSON.pretty_generate(out)
exit(results.all? { |r| r.dig(:shop, :shop_http) == "200" && r.dig(:shop, :products).to_i.positive? } ? 0 : 1)
