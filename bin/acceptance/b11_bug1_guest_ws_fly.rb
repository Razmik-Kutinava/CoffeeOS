#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.1 баг-1 — prep Fly: заказ + guest URL + barista login для MCP DevTools прогона WS.
#
#   FLY_BIN=flyctl ruby bin/acceptance/b11_bug1_guest_ws_fly.rb
#   node bin/acceptance/b11_bug1_guest_ws_mcp.mjs
#
# → tmp/b11_bug1_guest_ws_prep.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"

ROOT = File.expand_path("../..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B11_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
BARISTA_EMAIL = ENV.fetch("B11_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
OUT = ENV.fetch("OUT", File.join(ROOT, "tmp/b11_bug1_guest_ws_prep.json"))
DATE = Time.now.utc.strftime("%Y-%m-%d")
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

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

def curl_post_json(*args)
  raw = curl(*args, "-w", "\n%{http_code}")
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

def fly_runner(ruby)
  remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote_cmd)
  combined = [ out, err ].join.strip
  raise "fly runner failed: #{combined}" unless st.success?

  combined
end

def clear_barista_board!
  ruby = [
    "tid = #{TENANT_ID.inspect}",
    "shift = CashShift.find_by(tenant_id: tid, status: 'open')",
    "scope = Barista::BoardOrdersQuery.board_scope(tenant_id: tid, cash_shift: shift || :auto)",
    "scope = scope.where(status: %w[accepted preparing])",
    "count = scope.update_all(status: 'ready', updated_at: Time.current)",
    "puts \"cleared \#{count}\""
  ].join("; ")
  puts "board cleared: #{fly_runner(ruby)}"
end

suffix = Time.now.utc.strftime("%m%d%H%M")
load_fly_token!
clear_barista_board!
email = "b11-bug1-#{suffix}@coffeeos.dev"
shop_jar = File.join(Dir.tmpdir, "b11-bug1-shop-#{suffix}.cookies")
barista_jar = File.join(Dir.tmpdir, "b11-bug1-barista-#{suffix}.cookies")

api_key = shop_key(TENANT_ID)
curl("-c", shop_jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

products = JSON.parse(curl(
  "#{BASE}/shop/api/products",
  "-H", "X-Shop-Tenant: #{TENANT_ID}",
  "-H", "X-Shop-Api-Key: #{api_key}"
))
pid = products.dig("data", 0, "id")
raise "no product" unless pid

curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/email_otp/send",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { email: email }.to_json
)
code = fetch_otp(email)
raise "otp not fetched" unless code

curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { email: email, code: code }.to_json
)

curl(
  "-X", "POST", "#{BASE}/shop/api/cart/add",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
)

order_body, order_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/orders",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", {
    email: email,
    name: "B11-Bug1-#{suffix}",
    payment_method: "cash"
  }.to_json
)
raise "create order failed (#{order_http}): #{order_body}" unless order_http == 200

order_id = order_body["order_id"]
reconnect_token = order_body["reconnect_token"]
raise "missing order fields" if order_id.to_s.empty? || reconnect_token.to_s.empty?

guest_base = "#{BASE}/shop?tenant_id=#{TENANT_ID}"
guest_url = "#{guest_base}#/order/#{order_id}"
order_dom_id = "order_#{order_id}"

# Stale token from another order in sessionStorage (repro bug-1 before fix)
decoy_body, decoy_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/orders",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", {
    email: email,
    name: "Decoy",
    payment_method: "cash"
  }.to_json
)
stale_token = decoy_http == 200 ? decoy_body["reconnect_token"] : nil

payload = {
  task: "B1_1_bug1_guest_ws",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  barista_email: BARISTA_EMAIL,
  barista_password: PASSWORD,
  email: email,
  order_id: order_id,
  order_dom_id: order_dom_id,
  reconnect_token: reconnect_token,
  stale_reconnect_token: stale_token,
  guest_url: guest_url,
  guest_base: guest_base,
  barista_url: "#{BASE}/barista",
  shop_jar: shop_jar,
  barista_jar: barista_jar,
  screen_dir: "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b11_bug1_guest_ws_#{DATE}"
}

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
puts "written #{OUT}"
