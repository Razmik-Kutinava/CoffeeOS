#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 MCP e2e — витрина → заказ accepted (без смены статуса баристой).
#   FLY_BIN=flyctl ruby bin/acceptance/b21_mcp_e2e_prep.rb
# → tmp/b21_mcp_e2e_prep.json

require "json"
require "open3"
require "tmpdir"
require "fileutils"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
BARISTA_EMAIL = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
OUT = ENV.fetch("OUT", "tmp/b21_mcp_e2e_prep.json")
SCREEN_DIR = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10"
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

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

def csrf_token(html)
  html[/name="csrf-token" content="([^"]+)"/, 1]
end

def login_user!(email:, jar:)
  File.delete(jar) if File.exist?(jar)
  login_html = curl("-c", jar, "#{BASE}/login")
  token = csrf_token(login_html)
  raise "no csrf on login" if token.nil? || token.empty?

  hdr = curl(
    "-b", jar, "-c", jar, "-X", "POST", "#{BASE}/login",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[email]=#{email}",
    "--data-urlencode", "user[password]=#{PASSWORD}",
    "-D", "-", "-o", "-"
  )
  raise "login failed for #{email}" unless hdr.include?("302")
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
  machine = machines.find { |m| m["state"] == "started" } || machines.first
  machine&.dig("id") || raise("no fly machine")
end

def fetch_otp_from_fly(email)
  ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
  remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote_cmd)
  combined = [ out, err ].join
  code = combined.scan(/\b(\d{6})\b/).last&.first
  code = nil if code == "NONE"
  code
end

def ensure_barista_shift!(jar)
  board = curl("-b", jar, "#{BASE}/barista")
  return if board.include?("Смена открыта")

  token = csrf_token(board)
  raise "no csrf on barista" if token.nil? || token.empty?

  curl(
    "-b", jar, "-c", jar,
    "-X", "POST", "#{BASE}/barista/shift/open",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "opening_cash=0",
    "-o", NULL_DEV
  )
  board2 = curl("-b", jar, "#{BASE}/barista")
  raise "shift still closed after open" unless board2.include?("Смена открыта")
end

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b21-e2e-#{suffix}@coffeeos.dev"
shop_jar = File.join(Dir.tmpdir, "b21-e2e-shop-#{suffix}.cookies")
barista_jar = File.join(Dir.tmpdir, "b21-e2e-barista-#{suffix}.cookies")

api_key = shop_key(TENANT_ID)
curl("-c", shop_jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

products = JSON.parse(curl(
  "#{BASE}/shop/api/products",
  "-H", "X-Shop-Tenant: #{TENANT_ID}",
  "-H", "X-Shop-Api-Key: #{api_key}"
))
pid = products.dig("data", 0, "id")
raise "no product" unless pid

_, send_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/email_otp/send",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { email: email }.to_json
)
raise "otp send failed" unless send_http == 200

code = fetch_otp_from_fly(email)
raise "otp not fetched — FLY_BIN=flyctl auth login" unless code

_, verify_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { email: email, code: code }.to_json
)
raise "otp verify failed" unless verify_http == 200

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
  "--data-binary", { email: email, name: "B21-E2E-#{suffix}", payment_method: "cash" }.to_json
)
raise "create order failed" unless order_http == 200 && order_body["status"] == "accepted"

order_id = order_body["order_id"]
reconnect_token = order_body["reconnect_token"]
raise "missing order_id/reconnect_token" if order_id.to_s.empty? || reconnect_token.to_s.empty?

login_user!(email: BARISTA_EMAIL, jar: barista_jar)
ensure_barista_shift!(barista_jar)

guest_base = "#{BASE}/shop?tenant_id=#{TENANT_ID}"
payload = {
  task: "B21_mcp_e2e_prep",
  run_at: Time.now.utc.iso8601,
  base: BASE,
  tenant_id: TENANT_ID,
  barista_email: BARISTA_EMAIL,
  screen_dir: SCREEN_DIR,
  order_id: order_id,
  order_dom_id: "order_#{order_id}",
  reconnect_token: reconnect_token,
  guest_base: guest_base,
  guest_url: "#{guest_base}#/order/#{order_id}",
  vitrina_email: email,
  subtitles: {
    preparing: "Ваш заказ начали готовить",
    ready: "Заказ готов, забирайте!"
  },
  shop_jar: shop_jar,
  barista_jar: barista_jar
}

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
puts "written #{OUT}"
