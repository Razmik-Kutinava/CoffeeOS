#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.7 BR-7 — prep Fly: cart + unique email для MCP (OTP в UI на checkout).
#
#   FLY_BIN=flyctl ruby bin/acceptance/b17_br7_checkout_name_pay_prep_fly.rb
#   node bin/acceptance/b17_br7_checkout_name_pay_mcp.mjs
#
# → tmp/b17_br7_checkout_name_pay_prep.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"

ROOT = File.expand_path("../..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B17_TENANT_ID", "655aaccb-004a-4bb9-a50a-ce618854dda3")
OUT = ENV.fetch("OUT", File.join(ROOT, "tmp/b17_br7_checkout_name_pay_prep.json"))
DATE = Time.now.utc.strftime("%Y-%m-%d")

def load_fly_token!
  return if ENV["FLY_API_TOKEN"] && !ENV["FLY_API_TOKEN"].empty?

  cfg = File.expand_path("~/.fly/config.yml")
  return unless File.exist?(cfg)

  token = File.read(cfg)[/access_token:\s*(.+)/, 1]&.strip
  ENV["FLY_API_TOKEN"] = token if token && !token.empty?
end

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(6).join(' ')}" unless status.success?

  out
end

def curl_post_json(url, jar, headers:, body:)
  raw = curl("-c", jar, "-b", jar, "-X", "POST", url,
    *headers.flat_map { |k, v| [ "-H", "#{k}: #{v}" ] },
    "-d", body.to_json,
    "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [ JSON.parse(body_raw), http ]
end

def curl_get_json(url, jar, headers:)
  raw = curl("-c", jar, "-b", jar, url,
    *headers.flat_map { |k, v| [ "-H", "#{k}: #{v}" ] },
    "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [ JSON.parse(body_raw), http ]
end

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key" if key.nil? || key.empty?

  key
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  machines.find { |m| m["state"] == "started" }&.dig("id") || machines.first&.dig("id") || raise("no fly machine")
end

def fetch_otp(email)
  ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
  out, err, = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, "/rails/bin/rails runner #{ruby.inspect}")
  code = [ out, err ].join.scan(/\b(\d{6})\b/).last&.first
  code unless code == "NONE"
end

def first_product_id(tenant_id, jar, headers)
  body, http = curl_get_json("#{BASE}/shop/api/categories?tenant_id=#{tenant_id}", jar, headers: headers)
  raise "categories #{http}" unless http == 200

  cats = body.is_a?(Array) ? body : body["categories"] || body["data"] || []
  product = cats.flat_map { |c| c["products"] || [] }.find { |p| p["id"] && !p["id"].to_s.empty? }
  raise "no products in catalog" unless product

  product["id"]
end

load_fly_token!
suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b17-br7-#{suffix}@coffeeos.dev"
jar = File.join(Dir.tmpdir, "b17-br7-#{suffix}.cookies")
FileUtils.mkdir_p(File.dirname(OUT))

api_key = shop_key(TENANT_ID)
headers = {
  "Accept" => "application/json",
  "Content-Type" => "application/json",
  "X-Shop-Tenant" => TENANT_ID,
  "X-Shop-Api-Key" => api_key
}

curl("#{BASE}/shop?tenant_id=#{TENANT_ID}", "-c", jar, "-b", jar, "-o", File::NULL)
curl("-c", jar, "-b", jar, "-X", "DELETE", "#{BASE}/shop/api/cart?tenant_id=#{TENANT_ID}",
  "-H", "Accept: application/json", "-H", "X-Shop-Api-Key: #{api_key}", "-o", File::NULL)

product_id = first_product_id(TENANT_ID, jar, headers)
_, add_http = curl_post_json(
  "#{BASE}/shop/api/cart/add?tenant_id=#{TENANT_ID}",
  jar, headers: headers,
  body: { product_id: product_id, quantity: 1, selected_modifiers: [] }
)
raise "cart add failed #{add_http}" unless add_http == 200

prep = {
  scenario: "b17_br7_checkout_name_pay",
  task_id: "BR-7",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  shop_url: "#{BASE}/shop?tenant_id=#{TENANT_ID}",
  email: email,
  product_id: product_id,
  fly_app: FLY_APP,
  fly_bin: FLY_BIN,
  fly_machine_id: fly_machine_id,
  screen_dir: "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b17_br7_checkout_name_pay_after_#{DATE}",
  artifact: "docs/operations/milestones/veha_2/artifacts/demo-feedback/b17_br7_checkout_name_pay_post_deploy_#{DATE}.json"
}

File.write(OUT, JSON.pretty_generate(prep))
puts "Wrote #{OUT}"
puts JSON.pretty_generate(prep)
