#!/usr/bin/env ruby
# frozen_string_literal: true

# Smoke after per-tenant key seed. Does not disable FALLBACK.
# ruby bin/acceptance/v3_sec_shop_api_keys_seed_smoke.rb

require "json"
require "net/http"
require "uri"
require "cgi"
require "open3"
require "fileutils"

BASE = "https://coffeeos.fly.dev"
POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
POINT_B = "655aaccb-004a-4bb9-a50a-ce618854dda3"
SECRET = "config/secrets/shop_api_keys_fly_seed_2026-09-09.json"
ART_DIR = "docs/operations/milestones/veha_2/artifacts/v3_sec_shop_api_keys_seed/mcp/fly_v494_2026-09-09"

secrets = JSON.parse(File.read(SECRET))
by_slug = secrets["keys"].to_h { |k| [ k["slug"], k ] }
key_a = by_slug.fetch("demo-point-a").fetch("raw")
key_b = by_slug.fetch("demo-point-b").fetch("raw")

out, = Open3.capture2("fly", "machine", "exec", "9080d40db67238", "-a", "coffeeos", "printenv SHOP_API_KEY")
env_key = out.lines.map(&:strip).find { |l| l.match?(%r{\A[A-Za-z0-9+/=_-]{16,}\z}) }
raise "ENV SHOP_API_KEY empty" if env_key.to_s.empty?

def get(path, headers = {})
  uri = URI.join(BASE, path)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 15
  http.read_timeout = 30
  req = Net::HTTP::Get.new(uri)
  headers.each { |k, v| req[k] = v }
  http.request(req).code.to_i
end

checks = [
  { id: "A_key_on_A", http: get("/shop/api/cart?tenant_id=#{POINT_A}", "X-Shop-Api-Key" => key_a, "X-Shop-Tenant" => POINT_A), expect: 200 },
  { id: "A_key_on_B", http: get("/shop/api/cart?tenant_id=#{POINT_B}", "X-Shop-Api-Key" => key_a, "X-Shop-Tenant" => POINT_B), expect: 401 },
  { id: "B_key_on_B", http: get("/shop/api/cart?tenant_id=#{POINT_B}", "X-Shop-Api-Key" => key_b, "X-Shop-Tenant" => POINT_B), expect: 200 },
  { id: "B_key_on_A", http: get("/shop/api/cart?tenant_id=#{POINT_A}", "X-Shop-Api-Key" => key_b, "X-Shop-Tenant" => POINT_A), expect: 401 },
  { id: "no_key", http: get("/shop/api/cart?tenant_id=#{POINT_A}"), expect: 401 },
  { id: "query_key_dead", http: get("/shop/api/cart?tenant_id=#{POINT_A}&api_key=#{CGI.escape(key_a)}"), expect: 401 },
  { id: "env_fallback_still_on", http: get("/shop/api/cart?tenant_id=#{POINT_A}", "X-Shop-Api-Key" => env_key, "X-Shop-Tenant" => POINT_A), expect: 200 },
  { id: "categories_public", http: get("/shop/api/categories?tenant_id=#{POINT_A}"), expect: 200 }
]
checks.each { |c| c[:pass] = c[:http] == c[:expect] }
status = checks.all? { |c| c[:pass] } ? "PASS" : "FAIL"

FileUtils.mkdir_p(ART_DIR)
art = {
  date: "2026-09-09",
  fly_version: 494,
  fallback_disabled: false,
  point_a_prefix: by_slug["demo-point-a"]["prefix"],
  point_b_prefix: by_slug["demo-point-b"]["prefix"],
  checks: checks.map { |c| c.slice(:id, :http, :expect, :pass) },
  status: status
}
File.write(File.join(ART_DIR, "smoke_result.json"), JSON.pretty_generate(art))
File.write(
  File.join(ART_DIR, "MCP_RESULT.md"),
  <<~MD
    # Shop API keys seed — Fly v494

    **Status:** **#{status}**
    **FALLBACK:** still ON (ENV global не выключали)

    ## Seed
    - 17 sales_point keys issued (`seed-2026-09-09`)
    - RAW: `#{SECRET}` (gitignored)
    - Point A prefix: `#{by_slug['demo-point-a']['prefix']}` · Point B prefix: `#{by_slug['demo-point-b']['prefix']}`

    ## Smoke
    #{checks.map { |c| "- #{c[:pass] ? 'PASS' : 'FAIL'} #{c[:id]} (#{c[:http]}, expect #{c[:expect]})" }.join("\n")}
  MD
)

puts JSON.pretty_generate(art)
exit(status == "PASS" ? 0 : 1)
