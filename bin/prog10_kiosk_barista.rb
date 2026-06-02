#!/usr/bin/env ruby
# frozen_string_literal: true

# Блок 9 (прогон 10): kiosk auth → shop cash order → заказ на табло barista.
# Usage:
#   ruby bin/prog10_collect_kiosk_tokens.rb /tmp/prog10_kiosk_tokens.json
#   KIOSK_TOKENS_FILE=/tmp/prog10_kiosk_tokens.json ruby bin/prog10_kiosk_barista.rb
#   OUT=docs/operations/milestones/veha_2/artifacts/prog10/kiosk/prog10_kiosk_barista.json ruby bin/prog10_kiosk_barista.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
ORDER_DELAY = ENV.fetch("ORDER_DELAY_SEC", "7").to_f
PAYMENT = ENV.fetch("PAYMENT", "cash") # cash | card
_DEFAULT_OUT = "docs/operations/milestones/veha_2/artifacts/prog10/kiosk/prog10_kiosk_barista"
OUT = ENV.fetch("OUT") {
  PAYMENT == "card" ? "#{_DEFAULT_OUT}_card.json" : "#{_DEFAULT_OUT}.json"
}

POINTS = [
  { slug: "demo-a", tenant_id: "2fdee1ac-4674-41ee-b89e-87b45643f789", barista_expected: true,
    barista_email: "barista-a@demo.coffeeos.local" },
  { slug: "demo-b", tenant_id: "655aaccb-004a-4bb9-a50a-ce618854dda3", barista_expected: true,
    barista_email: "barista-b@demo.coffeeos.local" },
  { slug: "demo-prep", tenant_id: "d47165db-81c9-4e9d-bc50-e37fe610d86c", barista_expected: false,
    barista_email: "mcp-stf03-demo-prep-06021510@prog10.local" },
  { slug: "alpha-p1", tenant_id: "1c064640-4301-4435-8ded-c92fb075e9cc", barista_expected: true,
    barista_email: "mcp-stf03-alpha-p1-06021250@prog10.local" },
  { slug: "alpha-p2", tenant_id: "edf8a0a9-38e7-4049-b9c6-3e08c6c23a76", barista_expected: true,
    barista_email: "mcp-stf03-alpha-p2-06021250@prog10.local" },
  { slug: "alpha-p3", tenant_id: "d29fcf3a-da72-4a95-9683-9cfa71a2d865", barista_expected: true,
    barista_email: "mcp-stf03-alpha-p3-06021510@prog10.local" },
  { slug: "beta-p1", tenant_id: "03a4d457-e16f-4998-b764-69b3de083732", barista_expected: true,
    barista_email: "mcp-stf03-beta-p1-06021250@prog10.local" },
  { slug: "beta-p2", tenant_id: "628a937b-f4e2-43b7-bd7f-9fa44f031460", barista_expected: true,
    barista_email: "mcp-stf03-beta-p2-06021250@prog10.local" },
  { slug: "beta-p3", tenant_id: "b57c2a88-91a5-481e-b44f-29e29c77cfb5", barista_expected: true,
    barista_email: "mcp-stf03-beta-p3-06021510@prog10.local" }
].freeze

def run_curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(6).join(' ')}" unless status.success?

  out
end

def csrf_token(html)
  html[/name="csrf-token" content="([^"]+)"/, 1]
end

def pause
  sleep ORDER_DELAY if ORDER_DELAY.positive?
end

def login_user!(email:, jar:)
  File.delete(jar) if File.exist?(jar)
  login_html = run_curl("-c", jar, "#{BASE}/login")
  token = csrf_token(login_html)
  raise "no csrf on login for #{email}" if token.nil? || token.empty?

  hdr = run_curl(
    "-b", jar, "-c", jar,
    "-X", "POST", "#{BASE}/login",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[email]=#{email}",
    "--data-urlencode", "user[password]=#{PASSWORD}",
    "-D", "-", "-o", "-"
  )
  ok = hdr.include?("HTTP/2 302") || hdr.include?("HTTP/1.1 302")
  raise "login failed for #{email}" unless ok
end

def shop_key_for(tenant_id)
  html = run_curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?

  key
end

def kiosk_auth!(device_token)
  body = run_curl("-X", "POST", "#{BASE}/kiosk/api/auth", "-H", "X-Device-Token: #{device_token}")
  JSON.parse(body)
end

def kiosk_shop_order!(tenant_id:, key:, label:, payment_method: "cash")
  jar = "/tmp/prog10-k9-#{tenant_id[0, 8]}.cookies"
  File.delete(jar) if File.exist?(jar)
  run_curl("-c", jar, "#{BASE}/shop?tenant_id=#{tenant_id}", "-o", "/dev/null")

  products = JSON.parse(
    run_curl("#{BASE}/shop/api/products", "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}")
  )
  pid = products.dig("data", 0, "id")
  return { ok: false, error: "no products" } if pid.nil?

  run_curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
  )
  pause

  phone = format("+7905%07d", rand(10_000_000))
  raw = run_curl(
    "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { name: label, phone: phone, payment_method: payment_method }.to_json
  )
  parsed = JSON.parse(raw)
  oid = parsed["order_id"]
  status = parsed["status"]
  payment_url = parsed["payment_url"]
  ok_status = %w[accepted pending_payment].include?(status.to_s)
  card_ok = payment_method == "cash" || !payment_url.to_s.empty? || status == "accepted"
  {
    ok: !oid.nil? && ok_status && card_ok,
    order_id: oid,
    status: status,
    payment_url: payment_url ? "present" : nil,
    payment_method: payment_method,
    raw_error: parsed["error"]
  }
end

def http_code(path, jar:)
  run_curl("-b", jar, "-o", "/dev/null", "-w", "%{http_code}", "#{BASE}#{path}").strip
end

def order_json(path, jar:)
  run_curl("-b", jar, "#{BASE}#{path}")
end

tokens_path = ENV["KIOSK_TOKENS_FILE"].to_s
raise "set KIOSK_TOKENS_FILE (run bin/prog10_collect_kiosk_tokens.rb first)" if tokens_path.empty? || !File.exist?(tokens_path)

kiosk_tokens = JSON.parse(File.read(tokens_path))
shop_key = shop_key_for(POINTS.first[:tenant_id])
suffix = Time.now.utc.strftime("%m%d%H%M")

results = []
POINTS.each do |point|
  tid = point[:tenant_id]
  token = kiosk_tokens[tid]
  row = {
    slug: point[:slug],
    tenant_id: tid,
    barista_expected: point[:barista_expected],
    barista_email: point[:barista_email],
    kiosk_token_present: !token.nil? && !token.to_s.empty?,
    kiosk_auth: nil,
    kiosk_order: nil,
    barista_board_http: nil,
    barista_order_http: nil,
    barista_order_status: nil,
    barista_html_has_order: nil,
    pass: false
  }

  if token.nil? || token.to_s.empty?
    row[:kiosk_auth] = { ok: false, error: "missing token" }
    results << row
    next
  end

  auth = kiosk_auth!(token)
  row[:kiosk_auth] = { ok: !auth["tenant_id"].to_s.empty?, tenant_id: auth["tenant_id"] }
  pause

  label = "KIOSK-B9-#{PAYMENT}-#{point[:slug]}-#{suffix}"
  order_res = kiosk_shop_order!(tenant_id: tid, key: shop_key, label: label, payment_method: PAYMENT)
  row[:kiosk_order] = order_res
  pause

  staff_jar = "/tmp/prog10-k9-bar-#{point[:slug]}.cookies"
  begin
    login_user!(email: point[:barista_email], jar: staff_jar)
  rescue StandardError => e
    row[:barista_login_error] = e.message
    results << row
    next
  end

  board_code = http_code("/barista", jar: staff_jar)
  row[:barista_board_http] = board_code

  if order_res[:order_id]
    json_raw = order_json("/barista/orders/#{order_res[:order_id]}.json", jar: staff_jar)
    begin
      parsed = JSON.parse(json_raw)
      row[:barista_order_http] = parsed.key?("id") ? "200" : "error"
      row[:barista_order_status] = parsed["status"]
    rescue JSON::ParserError
      row[:barista_order_http] = "non-json"
    end

    html = run_curl("-b", staff_jar, "#{BASE}/barista")
    row[:barista_html_has_order] = html.include?(order_res[:order_id].to_s) || html.include?(label)
  end

  if point[:barista_expected]
    row[:pass] =
      row[:kiosk_auth][:ok] &&
      order_res[:ok] &&
      board_code == "200" &&
      row[:barista_order_http] == "200" &&
      %w[accepted preparing ready pending_payment].include?(row[:barista_order_status].to_s) ||
        (PAYMENT == "card" && order_res[:status] == "pending_payment" && order_res[:payment_url])
  else
    row[:pass] =
      row[:kiosk_auth][:ok] &&
      order_res[:ok] &&
      board_code == "302"
  end

  results << row
  pause
end

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  note: "block 9: kiosk auth + #{PAYMENT} order + barista visibility",
  payment_method: PAYMENT,
  order_label_suffix: suffix,
  results: results
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)

exit(results.all? { |r| r[:pass] } ? 0 : 1)
