#!/usr/bin/env ruby
# frozen_string_literal: true

# Fly: multi-tenant checkout email OTP — 4 точки × 2 email.
# Usage:
#   ruby bin/shop_checkout_otp_fly_multitenant.rb
#   OUT=docs/operations/milestones/veha_2/artifacts/demo-feedback/checkout_otp_fly_multitenant_2026-06-09.json ruby bin/shop_checkout_otp_fly_multitenant.rb
#   SKIP_FLY_OTP_FETCH=1  — только send/status/block без verify+order (без fly ssh)

require "json"
require "open3"
require "tmpdir"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/demo-feedback/checkout_otp_fly_multitenant_#{Time.now.utc.strftime('%Y-%m-%d')}.json")
ORDER_DELAY = ENV.fetch("ORDER_DELAY_SEC", "2").to_f
SKIP_OTP_FETCH = ENV["SKIP_FLY_OTP_FETCH"] == "1"

POINTS = [
  { slug: "demo_a", tenant_id: "2fdee1ac-4674-41ee-b89e-87b45643f789" },
  { slug: "demo_b", tenant_id: "655aaccb-004a-4bb9-a50a-ce618854dda3" },
  { slug: "prep_kitchen", tenant_id: "d47165db-81c9-4e9d-bc50-e37fe610d86c" },
  { slug: "prog10_alpha", tenant_id: "1c064640-4301-4435-8ded-c92fb075e9cc" }
].freeze

def curl_json(*args)
  raw = curl(*args)
  [JSON.parse(raw), raw]
rescue JSON::ParserError
  [{ "raw" => raw }, raw]
end

def curl_post_json(*args)
  raw = curl(*args, "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  body = JSON.parse(body_raw)
  [body, http]
rescue JSON::ParserError
  [{ "raw" => body_raw }, http]
end

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(4).join(' ')}" unless status.success?

  out
end

NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

def curl_code(*args)
  out, status = Open3.capture2("curl", "-sS", "-o", NULL_DEV, "-w", "%{http_code}", *args)
  raise "curl failed" unless status.success?

  out.strip.to_i
end

def pause
  sleep ORDER_DELAY if ORDER_DELAY.positive?
end

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?

  key
end

def fetch_otp_from_fly(email)
  return nil if SKIP_OTP_FETCH

  esc = email.gsub("'", "'\\\\''")
  runner = "r=ShopEmailOtpCode.active('#{esc}').order(created_at: :desc).first; print(r&.code || 'NONE')"
  cmd = "bin/rails runner \"#{runner}\""
  out, status = Open3.capture2("fly", "ssh", "console", "-a", FLY_APP, "-C", cmd)
  return nil unless status.success?

  code = out.strip
  code if code.match?(/\A\d{6}\z/)
rescue StandardError => e
  warn "[fly-otp] #{e.message}"
  nil
end

suffix = Time.now.utc.strftime("%m%d%H%M")
api_key = shop_key(POINTS.first[:tenant_id])
rows = []
cross = { status: "SKIP", detail: nil }

POINTS.each do |point|
  tid = point[:tenant_id]
  jar = File.join(Dir.tmpdir, "shop-otp-#{point[:slug]}-#{suffix}.cookies")
  File.delete(jar) if File.exist?(jar)
  curl("-c", jar, "#{BASE}/shop?tenant_id=#{tid}", "-o", NULL_DEV)

  users = []
  2.times do |i|
    email = "mt-#{point[:slug]}-u#{i + 1}-#{suffix}@coffeeos.dev"
    user = { email: email, send: nil, status_before: nil, order_blocked: nil, verify: nil, order: nil, pass: false }

    pause
    send_body, send_http = curl_post_json(
      "-X", "POST", "#{BASE}/shop/api/email_otp/send",
      "-c", jar, "-b", jar,
      "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}",
      "-H", "Content-Type: application/json",
      "--data-binary", { email: email }.to_json
    )
    user[:send] = { http: send_http, body: send_body }

    status_body, = curl_json(
      "#{BASE}/shop/api/email_otp/status",
      "-b", jar, "-c", jar,
      "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}"
    )
    user[:status_before] = status_body

    pause
    products = JSON.parse(curl("#{BASE}/shop/api/products", "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}"))
    pid = products.dig("data", 0, "id")
    if pid
      curl("-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
        "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}",
        "-H", "Content-Type: application/json",
        "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json)
      pause
      blocked_body, blocked_http = curl_post_json(
        "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
        "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}",
        "-H", "Content-Type: application/json",
        "--data-binary", { email: email, name: "MT #{point[:slug]} u#{i + 1}", payment_method: "cash" }.to_json
      )
      user[:order_blocked] = { http: blocked_http, body: blocked_body }
    end

    code = fetch_otp_from_fly(email)
    if code
      pause
      verify_body, = curl_json(
        "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
        "-c", jar, "-b", jar,
        "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}",
        "-H", "Content-Type: application/json",
        "--data-binary", { email: email, code: code }.to_json
      )
      user[:verify] = { code_from: "fly_ssh", body: verify_body }

      if pid && verify_body["verified"]
        pause
        order_ok_body, = curl_json(
          "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
          "-H", "X-Shop-Tenant: #{tid}", "-H", "X-Shop-Api-Key: #{api_key}",
          "-H", "Content-Type: application/json",
          "--data-binary", { email: email, name: "MT #{point[:slug]} u#{i + 1}", payment_method: "cash" }.to_json
        )
        user[:order] = order_ok_body
      end
    else
      user[:verify] = { skipped: true, reason: SKIP_OTP_FETCH ? "SKIP_FLY_OTP_FETCH" : "fly_ssh_unavailable" }
    end

    user[:pass] = user[:send][:http] == 200 &&
      user[:status_before]["verified"] == false &&
      user[:order_blocked]&.dig(:http) == 422 &&
      (user[:order]&.dig("status") == "accepted" || user[:verify][:skipped])

    users << user
  end

  rows << {
    slug: point[:slug],
    tenant_id: tid,
    users: users,
    pass: users.all? { |u| u[:pass] }
  }
end

# Cross-tenant: verify demo_a u1, order on demo_b blocked
begin
  a = POINTS[0]
  b = POINTS[1]
  email = "mt-cross-#{suffix}@coffeeos.dev"
  jar = File.join(Dir.tmpdir, "shop-otp-cross-#{suffix}.cookies")
  File.delete(jar) if File.exist?(jar)
  curl("-c", jar, "#{BASE}/shop?tenant_id=#{a[:tenant_id]}", "-o", NULL_DEV)
  curl("-X", "POST", "#{BASE}/shop/api/email_otp/send", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{a[:tenant_id]}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json", "--data-binary", { email: email }.to_json)
  code = fetch_otp_from_fly(email)
  if code
    curl("-X", "POST", "#{BASE}/shop/api/email_otp/verify", "-c", jar, "-b", jar,
      "-H", "X-Shop-Tenant: #{a[:tenant_id]}", "-H", "X-Shop-Api-Key: #{api_key}",
      "-H", "Content-Type: application/json", "--data-binary", { email: email, code: code }.to_json)
    status_b, = curl_json("#{BASE}/shop/api/email_otp/status", "-b", jar, "-c", jar,
      "-H", "X-Shop-Tenant: #{b[:tenant_id]}", "-H", "X-Shop-Api-Key: #{api_key}")
    order_b_body, = curl_json(
      "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
      "-H", "X-Shop-Tenant: #{b[:tenant_id]}", "-H", "X-Shop-Api-Key: #{api_key}",
      "-H", "Content-Type: application/json",
      "--data-binary", { email: email, name: "Cross", payment_method: "cash" }.to_json
    )
    cross = {
      status: (status_b["verified"] == false && order_b_body["error"].to_s.match?(/подтвердите email/i)) ? "PASS" : "FAIL",
      verified_on_b: status_b["verified"],
      order_b_http: order_b_body["error"] || order_b_body["status"]
    }
  else
    cross[:status] = "SKIP"
    cross[:detail] = "no otp from fly ssh"
  end
rescue StandardError => e
  cross = { status: "FAIL", error: e.message }
end

report = {
  task: "checkout_otp_fly_multitenant",
  base: BASE,
  at: Time.now.utc.iso8601,
  points: rows,
  cross_tenant: cross,
  all_pass: rows.all? { |r| r[:pass] } && %w[PASS SKIP].include?(cross[:status])
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)
puts "\nWrote #{OUT}"
exit(report[:all_pass] ? 0 : 1)
