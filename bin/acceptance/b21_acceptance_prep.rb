#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 formal acceptance prep — заказы, модификаторы, FIFO, push, смена.
#   FLY_BIN=flyctl ruby bin/acceptance/b21_acceptance_prep.rb
# → tmp/b21_acceptance_prep.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
BARISTA_EMAIL = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
OUT = ENV.fetch("OUT", "tmp/b21_acceptance_prep.json")
SCREEN_DIR = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10"
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"
PUSH_TOKEN = ENV.fetch("B21_PUSH_TOKEN", "b21-acceptance-fcm-token-#{Time.now.to_i}")

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

def fly_runner(ruby)
  remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote_cmd)
  combined = [ out, err ].join.strip
  raise "fly runner failed: #{combined}" unless st.success?

  combined
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
  raise "shift still closed" unless board2.include?("Смена открыта")
end

def shop_checkout!(shop_jar:, api_key:, email:, label:)
  _, send_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/send",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email }.to_json
  )
  raise "otp send failed" unless send_http == 200

  code = fetch_otp_from_fly(email)
  raise "otp not fetched" unless code

  _, verify_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, code: code }.to_json
  )
  raise "otp verify failed" unless verify_http == 200
end

def shop_create_order!(shop_jar:, api_key:, email:, label:, product_id:)
  curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: product_id, quantity: 1, selected_modifiers: [] }.to_json
  )

  body, http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/orders",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, name: label, payment_method: "cash" }.to_json
  )
  raise "create order failed #{label}" unless http == 200 && body["status"] == "accepted"

  body
end

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b21-acc-#{suffix}@coffeeos.dev"
shop_jar = File.join(Dir.tmpdir, "b21-acc-shop-#{suffix}.cookies")
barista_jar = File.join(Dir.tmpdir, "b21-acc-barista-#{suffix}.cookies")

api_key = shop_key(TENANT_ID)
barista_jar_early = File.join(Dir.tmpdir, "b21-acc-barista-open-#{suffix}.cookies")
login_user!(email: BARISTA_EMAIL, jar: barista_jar_early)
ensure_barista_shift!(barista_jar_early)

curl("-c", shop_jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

products = JSON.parse(curl(
  "#{BASE}/shop/api/products",
  "-H", "X-Shop-Tenant: #{TENANT_ID}",
  "-H", "X-Shop-Api-Key: #{api_key}"
))
pid = products.dig("data", 0, "id")
raise "no product" unless pid

shop_checkout!(shop_jar: shop_jar, api_key: api_key, email: email, label: "acc")

# Сессия гостя после первого заказа — надёжнее для push/register
shop_create_order!(
  shop_jar: shop_jar, api_key: api_key, email: email,
  label: "B21-SESSION-#{suffix}", product_id: pid
)

push_body, push_http = curl_post_json(
  "-X", "POST", "#{BASE}/shop/api/push/register",
  "-c", shop_jar, "-b", shop_jar,
  "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
  "-H", "Content-Type: application/json",
  "--data-binary", { push_token: PUSH_TOKEN, push_enabled: true }.to_json
)
raise "push register failed http=#{push_http} body=#{push_body.inspect}" unless push_http == 200 && push_body["registered"]

# FIFO: older first
fifo_older = shop_create_order!(shop_jar: shop_jar, api_key: api_key, email: email, label: "B21-FIFO-OLD-#{suffix}", product_id: pid)
sleep 3
fifo_newer = shop_create_order!(shop_jar: shop_jar, api_key: api_key, email: email, label: "B21-FIFO-NEW-#{suffix}", product_id: pid)

main = shop_create_order!(shop_jar: shop_jar, api_key: api_key, email: email, label: "B21-MAIN-#{suffix}", product_id: pid)
cancel = shop_create_order!(shop_jar: shop_jar, api_key: api_key, email: email, label: "B21-CANCEL-#{suffix}", product_id: pid)

main_id = main["order_id"]
cancel_id = cancel["order_id"]

mods_json = {
  "selected_modifiers" => [ { "name" => "Со льдом" } ],
  "removed_modifiers" => [ { "name" => "Сахар" } ]
}.to_json
mods_ruby = [
  "order = Order.find(#{main_id.inspect})",
  "item = order.order_items.first",
  "raise 'no item' unless item",
  "conn = ActiveRecord::Base.connection",
  "conn.execute('SET LOCAL row_security = off')",
  "conn.execute(\"SET LOCAL app.current_tenant_id = \#{conn.quote(order.tenant_id.to_s)}\")",
  "rows = conn.exec_update(\"UPDATE order_items SET modifier_options = \#{conn.quote(#{mods_json.inspect})}::jsonb WHERE id = \#{conn.quote(item.id.to_s)}\", 'SQL', [])",
  "raise 'update 0 rows' if rows.to_i.zero?",
  "puts OrderItem.find(item.id).modifier_options.to_json"
].join("; ")
mods_out = fly_runner(mods_ruby)
raise "modifiers patch failed: #{mods_out}" unless mods_out.include?("Со льдом") && mods_out.include?("Сахар")

login_user!(email: BARISTA_EMAIL, jar: barista_jar)

guest_base = "#{BASE}/shop?tenant_id=#{TENANT_ID}"
payload = {
  task: "B21_acceptance_prep",
  run_at: Time.now.utc.iso8601,
  base: BASE,
  tenant_id: TENANT_ID,
  barista_email: BARISTA_EMAIL,
  screen_dir: SCREEN_DIR,
  vitrina_email: email,
  push_token: PUSH_TOKEN,
  push_registered: push_body["registered"],
  main_order_id: main_id,
  main_order_dom_id: "order_#{main_id}",
  reconnect_token: main["reconnect_token"],
  fifo_older_id: fifo_older["order_id"],
  fifo_older_dom_id: "order_#{fifo_older['order_id']}",
  fifo_newer_id: fifo_newer["order_id"],
  fifo_newer_dom_id: "order_#{fifo_newer['order_id']}",
  cancel_order_id: cancel_id,
  cancel_order_dom_id: "order_#{cancel_id}",
  guest_base: guest_base,
  subtitles: {
    preparing: "Ваш заказ начали готовить",
    ready: "Заказ готов, забирайте!"
  },
  modifiers: {
    added: "+ СО ЛЬДОМ",
    removed: "БЕЗ Сахар"
  },
  shop_jar: shop_jar,
  barista_jar: barista_jar
}

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
puts "written #{OUT}"
