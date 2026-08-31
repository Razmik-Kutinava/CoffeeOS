#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../support/shop_api_key"

# Fly MCP Point A — v461 undeployed commits (2026-08-28 session).
#
# Covers: OTP log safety (code path), fail-redirect ownership, SHOP_SIMULATE=0, shop cash block.
#
#   ruby bin/acceptance/fly_v461_mcp_acceptance.rb

require "json"
require "open3"
require "tmpdir"
require "fileutils"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "fly")
TENANT_ID = ENV.fetch("TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT_DIR = File.expand_path("../../docs/operations/milestones/veha_2/artifacts/mcp/fly_v461_#{DATE}", __dir__)
OUT_JSON = File.join(OUT_DIR, "mcp_result.json")
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(4).join(' ')}" unless status.success?

  out
end

def curl_http(*args)
  curl(*args, "-o", NULL_DEV, "-w", "%{http_code}").strip.to_i
end

def curl_post_json(*args)
  raw = curl(*args, "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  body = JSON.parse(body_raw)
  [ body, http ]
rescue JSON::ParserError
  [ { "raw" => body_raw }, http ]
end

def shop_key(_tenant_id = nil)
  resolve_shop_api_key(fly_env: (respond_to?(:fly_env, true) ? method(:fly_env) : nil))
end

def fly_web_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
  web&.dig("id") || machines.find { |m| m["state"] == "started" }&.dig("id") || raise("no machine")
end

def fly_env(key)
  out, = Open3.capture2(FLY_BIN, "machine", "exec", fly_web_machine_id, "-a", FLY_APP, "printenv #{key}")
  out.strip.lines.reject { |l| l.match?(/Warning:|^--/) || l.include?("Metrics token") }.last&.strip
end

def fly_release_version
  out, status = Open3.capture2(FLY_BIN, "releases", "-a", FLY_APP, "--json")
  return nil unless status.success?

  JSON.parse(out).first&.dig("Version")
end

def fetch_otp_from_fly(email)
  ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
  remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, = Open3.capture3(FLY_BIN, "machine", "exec", fly_web_machine_id, "-a", FLY_APP, remote_cmd)
  combined = [ out, err ].join
  code = combined.scan(/\b(\d{6})\b/).last&.first
  code = nil if code == "NONE"
  code
end

FileUtils.mkdir_p(OUT_DIR)

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "v461-mcp-#{suffix}@coffeeos.dev"
checks = []
meta = {
  task: "fly_v461_mcp_acceptance",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  head: `git rev-parse --short HEAD`.strip,
  deploy_commits: [
    "bea1c226 OTP log leak",
    "5a061aa6 fail-redirect ownership",
    "a0023a8a SHOP_SIMULATE default 0",
    "1220d3e2 block shop cash online"
  ]
}

begin
  checks << { id: "P0_up", pass: curl_http("#{BASE}/up") == 200, http: curl_http("#{BASE}/up") }
  checks << { id: "P1_shop_point_a", pass: curl_http("#{BASE}/shop?tenant_id=#{TENANT_ID}") == 200 }

  rel = fly_release_version
  checks << { id: "P2_release_v461", pass: rel.to_i >= 461, version: rel }

  simulate = fly_env("SHOP_SIMULATE_PAYMENT")
  checks << { id: "P3_simulate_off", pass: simulate == "0", value: simulate }

  webhook_raw = curl(
    "-X", "POST", "#{BASE}/callbacks/tbank",
    "-H", "Content-Type: application/json",
    "--data-binary", { Token: "invalid" }.to_json,
    "-w", "\n%{http_code}"
  )
  wh_lines = webhook_raw.lines
  wh_http = wh_lines.last.to_s.strip.to_i
  wh_body = wh_lines[0..-2].join
  checks << {
    id: "P4_webhook_invalid_token",
    pass: wh_http == 401 && wh_body.include?("invalid token"),
    http: wh_http,
    body: wh_body[0, 120]
  }

  api_key = shop_key(TENANT_ID)
  jar = File.join(Dir.tmpdir, "v461-mcp-#{suffix}.cookies")
  File.delete(jar) if File.exist?(jar)
  curl("-c", jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)

  products = JSON.parse(curl(
    "#{BASE}/shop/api/products",
    "-H", "X-Shop-Tenant: #{TENANT_ID}",
    "-H", "X-Shop-Api-Key: #{api_key}"
  ))
  pid = products.dig("data", 0, "id")
  raise "no product" unless pid

  curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/send",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email }.to_json
  )
  code = fetch_otp_from_fly(email)
  raise "otp not fetched" unless code

  curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, code: code }.to_json
  )

  curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: pid, quantity: 1, selected_modifiers: [] }.to_json
  )

  cash_body, cash_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/orders",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, name: "V461 Cash", payment_method: "cash" }.to_json
  )
  checks << {
    id: "P5_shop_cash_rejected",
    pass: cash_http == 422 && cash_body["error"] == "cash payment not available online",
    http: cash_http,
    error: cash_body["error"]
  }

  card_body, card_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/orders",
    "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email, name: "V461 Card", payment_method: "card" }.to_json
  )
  order_id = card_body["order_id"]
  checks << {
    id: "P6_card_not_simulated_accepted",
    pass: card_http == 200 && card_body["status"] == "pending_payment" && !card_body["payment_url"].to_s.empty?,
    http: card_http,
    status: card_body["status"],
    order_id: order_id
  }

  if order_id.to_s != ""
    fail_loc = curl(
      "-D", "-", "-o", NULL_DEV,
      "#{BASE}/payment/fail?order_id=#{order_id}"
    )
    fail_http = fail_loc[/^HTTP\/[\d.]+ (\d+)/i, 1].to_i
    fail_redirect = fail_loc.match?(/location: .*payment-result\?status=fail/i)
    checks << {
      id: "P7_fail_redirect_no_ownership",
      pass: fail_http == 302 && fail_redirect,
      http: fail_http,
      note: "journal без reconnect_token — заказ остаётся pending (unit-tested)"
    }
  end

  meta[:checks] = checks
  meta[:status] = checks.all? { |c| c[:pass] } ? "PASS" : "PARTIAL"
rescue StandardError => e
  meta[:error] = "#{e.class}: #{e.message}"
  meta[:backtrace] = e.backtrace&.first(5)
  meta[:checks] = checks
  meta[:status] = "FAIL"
ensure
  File.write(OUT_JSON, JSON.pretty_generate(meta))
  puts JSON.pretty_generate(meta)
  puts "written #{OUT_JSON}"
  exit(meta[:status] == "PASS" ? 0 : 1)
end
