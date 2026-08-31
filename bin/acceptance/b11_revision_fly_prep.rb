#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../support/shop_api_key"

# Подготовка заказа на Fly для B1.1 ревизии R4 (скрины 4 шагов прогресс-бара).
#   FLY_BIN=flyctl ruby bin/acceptance/b11_revision_fly_prep.rb
#
# Пишет tmp/b11_revision_fly_prep.json (order_id, reconnect_token, guest_url, email).

require "json"
require "open3"
require "fileutils"
require "tmpdir"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B11_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
OUT = ENV.fetch("OUT", "tmp/b11_revision_fly_prep.json")
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

def shop_key(_tenant_id = nil)
  resolve_shop_api_key(fly_env: (respond_to?(:fly_env, true) ? method(:fly_env) : nil))
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed — need #{FLY_BIN} auth login" unless status.success?

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

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b11-revision-#{suffix}@coffeeos.dev"
shop_jar = File.join(Dir.tmpdir, "b11-revision-shop-#{suffix}.cookies")

api_key = shop_key(TENANT_ID)
curl("-c", shop_jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

products = JSON.parse(curl(
  "#{BASE}/shop/api/products",
  "-H", "X-Shop-Tenant: #{TENANT_ID}",
  "-H", "X-Shop-Api-Key: #{api_key}"
))
pid = products.dig("data", 0, "id")
raise "no product on tenant" unless pid

_, send_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/email_otp/send",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { email: email }.to_json
)
raise "otp send failed (#{send_http})" unless send_http == 200

code = fetch_otp_from_fly(email)
raise "otp not fetched — #{FLY_BIN} auth login" unless code

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

# card → pending_payment (шаг «Принят»); cash сразу accepted — для 4 шагов нужен card
order_body, order_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/orders",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", {
    email: email,
    name: "B11-Revision-#{suffix}",
    payment_method: "card"
  }.to_json
)
raise "create order failed (#{order_http}): #{order_body}" unless order_http == 200

order_id = order_body["order_id"]
reconnect_token = order_body["reconnect_token"]
status = order_body["status"]
raise "missing order_id" if order_id.to_s.empty?
raise "missing reconnect_token" if reconnect_token.to_s.empty?

guest_base = "#{BASE}/shop?tenant_id=#{TENANT_ID}"
guest_url = "#{guest_base}#/order/#{order_id}"

payload = {
  task: "B1_1_revision_fly_prep",
  date: Time.now.utc.strftime("%Y-%m-%d"),
  base: BASE,
  tenant_id: TENANT_ID,
  email: email,
  product_id: pid,
  order_id: order_id,
  reconnect_token: reconnect_token,
  initial_status: status,
  payment_method: "card",
  guest_url: guest_url,
  guest_base: guest_base,
  shop_url: guest_base,
  shop_jar: shop_jar
}

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
puts "written #{OUT}"
