#!/usr/bin/env ruby
# frozen_string_literal: true

# Fly smoke: B2.1 табло бариста — login, разметка B2.1, витрина → табло.
#
#   ruby bin/b21_barista_board_fly_smoke.rb
#   FLY_BIN=flyctl ruby bin/b21_barista_board_fly_smoke.rb
#
# Стенд Fly (demo A) — чтобы табло не врало:
# - На проде: board_scope (смена + витрина с opened_at), без limit(50) — новые заказы не теряются.
# - Периодически: закрыть смену в панели менеджера ИЛИ перевести старые accepted → issued (демо-уборка).
# - Перед smoke/e2e: лучше открыть новую смену, чем чистить заказы вручную каждый раз.

require "json"
require "open3"
require "shellwords"
require "tmpdir"
require "benchmark"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "fly")
TENANT_ID = ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
BARISTA_EMAIL = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = ENV.fetch(
  "OUT",
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_fly_smoke_#{DATE}.json"
)
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

def present?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(6).join(' ')}" unless status.success?

  out
end

def curl_json(*args)
  JSON.parse(curl(*args))
end

def curl_post_json(*args)
  raw = curl(*args, "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [JSON.parse(body_raw), http]
rescue JSON::ParserError
  [{ "raw" => body_raw }, http]
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
    "-b", jar, "-c", jar,
    "-X", "POST", "#{BASE}/login",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[email]=#{email}",
    "--data-urlencode", "user[password]=#{PASSWORD}",
    "-D", "-", "-o", "-"
  )
  ok = hdr.include?("302")
  raise "login failed for #{email}" unless ok
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
  combined = [out, err].join
  code = combined.scan(/\b(\d{6})\b/).last&.first
  code = nil if code == "NONE"
  code
rescue StandardError => e
  warn "[fly-otp] #{e.message}"
  nil
end

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b21-fly-#{suffix}@coffeeos.dev"
jar = File.join(Dir.tmpdir, "b21-fly-#{suffix}.cookies")
shop_jar = File.join(Dir.tmpdir, "b21-shop-#{suffix}.cookies")

result = {
  task: "B2_1_barista_board_fly_smoke",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  barista_email: BARISTA_EMAIL,
  vitrina_email: email,
  checks: [],
  status: "FAIL"
}

begin
  login_user!(email: BARISTA_EMAIL, jar: jar)
  result[:checks] << { id: "barista_login", pass: true }

  board_http = curl("-b", jar, "-o", NULL_DEV, "-w", "%{http_code}", "#{BASE}/barista").strip.to_i
  board_html = curl("-b", jar, "#{BASE}/barista")
  result[:checks] << { id: "barista_board_http", pass: board_http == 200, http: board_http }

  layout_markers = {
    kanban_ids: board_html.include?('id="orders-new"') && board_html.include?('id="orders-preparing"'),
    no_drag_hint: !board_html.include?("Перетащите карточку"),
    footer_hint: board_html.include?("нажмите кнопку на карточке"),
    turbo_cable: board_html.include?("turbo-cable-stream-source")
  }
  result[:checks] << {
    id: "b21_board_layout",
    pass: layout_markers.values.all?,
    markers: layout_markers
  }

  api_key = shop_key(TENANT_ID)
  curl("-c", shop_jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

  products = curl_json(
    "#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{TENANT_ID}",
    "-H", "X-Shop-Api-Key: #{api_key}"
  )
  pid = products.dig("data", 0, "id")
  raise "no product" unless pid

  send_body, send_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/send",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email }.to_json
  )
  result[:checks] << { id: "vitrina_otp_send", pass: send_http == 200, http: send_http }

  code = fetch_otp_from_fly(email)
  unless code
    result[:checks] << {
      id: "vitrina_otp_fetch",
      pass: false,
      skip: true,
      note: "fly machine exec недоступен (flyctl auth login) — vitrina→board не проверен"
    }
    result[:status] = result[:checks].reject { |c| c[:skip] }.all? { |c| c[:pass] } ? "PARTIAL" : "FAIL"
    raise "otp not fetched — fly exec unavailable"
  end

  verify_body, verify_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, code: code }.to_json
  )
  result[:checks] << { id: "vitrina_otp_verify", pass: verify_http == 200 && verify_body["verified"], http: verify_http }

  curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
  )

  order_label = "B21-FLY-#{suffix}"
  order_body, order_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/orders",
    "-c", shop_jar, "-b", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, name: order_label, payment_method: "cash" }.to_json
  )
  order_id = order_body["order_id"]
  order_number = order_body["order_number"]
  result[:checks] << {
    id: "vitrina_create_order",
    pass: order_http == 200 && present?(order_id) && order_body["status"] == "accepted",
    http: order_http,
    order_id: order_id,
    order_number: order_number
  }

  order_dom_id = "order_#{order_id}"
  board_after = nil
  on_board = false
  5.times do |attempt|
    sleep attempt.zero? ? 2 : 1
    board_after = curl("-b", jar, "#{BASE}/barista")
    on_board = board_after.include?(%(id="#{order_dom_id}")) ||
               board_after.include?(%(id='#{order_dom_id}'))
    break if on_board
  end
  result[:checks] << {
    id: "vitrina_order_on_barista_board",
    pass: on_board,
    order_id: order_id,
    order_dom_id: order_dom_id,
    order_number: order_number,
    note: on_board ? nil : "карточка #{order_dom_id} не найдена на /barista после retry"
  }

  card_html = board_after.to_s
  b21_markers = {
    order_card: card_html.include?('class="card order-card'),
    status_button: card_html.include?("card-btn-status"),
    gotovitsya: card_html.include?("ГОТОВИТСЯ"),
    cancel_overlay: card_html.include?("СТОП! ЗАКАЗ ОТМЕНЁН"),
    cancel_confirm: card_html.include?("ПОДТВЕРДИТЬ ОТМЕНУ")
  }
  result[:checks] << {
    id: "b21_board_markup",
    pass: on_board && b21_markers.values.all?,
    markers: b21_markers,
    deploy_note: b21_markers.values.all? ? nil : "нужен accepted-заказ на табло (ГОТОВИТСЯ в карточке)"
  }

  show_body = curl_json(
    "#{BASE}/shop/api/orders/#{order_id}",
    "-b", shop_jar, "-c", shop_jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}"
  )
  result[:checks] << {
    id: "guest_order_status_api",
    pass: show_body["status"] == "accepted" && present?(show_body["order_number"]),
    status: show_body["status"]
  }

  result[:status] = result[:checks].all? { |c| c[:pass] } ? "PASS" : "FAIL"
rescue StandardError => e
  result[:error] = "#{e.class}: #{e.message}"
  result[:status] = "FAIL" unless result[:status] == "PARTIAL"
ensure
  File.write(OUT, JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
  puts "written #{OUT}"
  exit(result[:status] == "PASS" ? 0 : 1)
end
