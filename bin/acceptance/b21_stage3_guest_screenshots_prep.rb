#!/usr/bin/env ruby
# frozen_string_literal: true

# Подготовка заказа на Fly для скринов stage3 guest (preparing / ready).
#   FLY_BIN=flyctl ruby bin/acceptance/b21_stage3_guest_screenshots_prep.rb
#
# Пишет JSON: tmp/b21_stage3_guest_prep.json (order_id, reconnect_token, guest_url)

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
OUT = ENV.fetch("OUT", "tmp/b21_stage3_guest_prep.json")
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

def barista_update_status!(jar:, order_id:, status:)
  board = curl("-b", jar, "#{BASE}/barista")
  token = csrf_token(board)
  raise "no csrf on barista board" if token.nil? || token.empty?

  hdr = curl(
    "-b", jar, "-c", jar,
    "-X", "PATCH", "#{BASE}/barista/orders/#{order_id}/update_status",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "status=#{status}",
    "-D", "-", "-o", NULL_DEV
  )
  raise "barista status #{status} failed" unless hdr.include?("302") || hdr.include?("200")
end

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b21-stage3-#{suffix}@coffeeos.dev"
shop_jar = File.join(Dir.tmpdir, "b21-stage3-shop-#{suffix}.cookies")
barista_jar = File.join(Dir.tmpdir, "b21-stage3-barista-#{suffix}.cookies")

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
raise "otp not fetched — need FLY_BIN=flyctl and flyctl auth login" unless code

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
  "--data-binary", { email: email, name: "B21-STAGE3-#{suffix}", payment_method: "cash" }.to_json
)
raise "create order failed" unless order_http == 200

order_id = order_body["order_id"]
reconnect_token = order_body["reconnect_token"]
raise "missing order_id or reconnect_token" if order_id.to_s.empty? || reconnect_token.to_s.empty?

login_user!(email: BARISTA_EMAIL, jar: barista_jar)

board = curl("-b", barista_jar, "#{BASE}/barista")
token = csrf_token(board)
unless board.include?("Смена открыта") || board.include?("count-new")
  curl(
    "-b", barista_jar, "-c", barista_jar,
    "-X", "POST", "#{BASE}/barista/shift/open",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "opening_cash=0",
    "-o", NULL_DEV
  )
end

system("ruby", "bin/acceptance/b21_stage3_fly_status.rb", "preparing", order_id) ||
  raise("fly status preparing failed")

guest_base = "#{BASE}/shop?tenant_id=#{TENANT_ID}"
guest_url = "#{guest_base}#/order/#{order_id}"

payload = {
  task: "B21_stage3_guest_screenshots_prep",
  date: Time.now.utc.strftime("%Y-%m-%d"),
  base: BASE,
  tenant_id: TENANT_ID,
  order_id: order_id,
  reconnect_token: reconnect_token,
  guest_url: guest_url,
  guest_base: guest_base,
  subtitles: {
    preparing: "Ваш заказ начали готовить",
    ready: "Заказ готов, забирайте!"
  },
  barista_jar: barista_jar,
  shop_jar: shop_jar
}

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
puts "written #{OUT}"
