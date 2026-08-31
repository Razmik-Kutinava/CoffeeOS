#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../support/shop_api_key"

# Fly MCP — Shop REVIEW G-04/G-05 + user/cards + categories (post v473).
#   ruby bin/acceptance/fly_shop_review_mcp.rb

require "json"
require "open3"
require "fileutils"
require "uri"
require "tmpdir"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "fly")
TENANT_ID = ENV.fetch("TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT_DIR = File.expand_path("../../docs/operations/milestones/veha_2/artifacts/mcp/fly_shop_review_#{DATE}", __dir__)
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

def curl_json(*args)
  JSON.parse(curl(*args))
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

def fly_web_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
  web&.dig("id") || raise("no web machine")
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
checks = []
meta = {
  task: "fly_shop_review_mcp",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  head: `git rev-parse --short HEAD`.strip,
  release: fly_release_version
}

begin
  api_key = resolve_shop_api_key(fly_env: method(:fly_env))
  hdrs = [ "-H", "X-Shop-Tenant: #{TENANT_ID}", "-H", "X-Shop-Api-Key: #{api_key}" ]

  # G-04: phone_otp/status must not auto-bind by phone lookup
  phone = "+7900#{suffix[-7..]}"
  status_body = curl_json(
    "#{BASE}/shop/api/phone_otp/status?phone=#{URI.encode_www_form_component(phone)}",
    *hdrs
  )
  checks << {
    id: "S1_phone_otp_status_no_autobind",
    pass: status_body["verified"] == false,
    verified: status_body["verified"],
    phone: status_body["phone"]
  }

  # user/cards: email param without verified session → empty
  cards_body = curl_json(
    "#{BASE}/shop/api/user/cards?email=victim-#{suffix}@coffeeos.dev",
    *hdrs
  )
  checks << {
    id: "S2_user_cards_email_param_empty",
    pass: cards_body["cards"] == [] && cards_body["primary"].nil?,
    cards_count: cards_body["cards"]&.length
  }

  # user/cards: after OTP restore via email_otp/status + session
  email_a = "mcp-a-#{suffix}@coffeeos.dev"
  email_b = "mcp-b-#{suffix}@coffeeos.dev"
  jar_a = File.join(Dir.tmpdir, "shop-mcp-a-#{suffix}.cookies")
  jar_b = File.join(Dir.tmpdir, "shop-mcp-b-#{suffix}.cookies")
  [ jar_a, jar_b ].each { |j| File.delete(j) if File.exist?(j) }

  curl("-c", jar_a, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)
  curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/send",
    "-c", jar_a, "-b", jar_a, *hdrs,
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email_a }.to_json
  )
  code_a = fetch_otp_from_fly(email_a)
  raise "otp A missing" unless code_a

  verify_a, = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
    "-c", jar_a, "-b", jar_a, *hdrs,
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email_a, code: code_a }.to_json
  )
  refresh_a = verify_a["refresh_token"]
  raise "refresh A missing" unless refresh_a.to_s != ""

  # G-05: logout B must not deactivate A's refresh
  curl("-c", jar_b, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)
  curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/send",
    "-c", jar_b, "-b", jar_b, *hdrs,
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email_b }.to_json
  )
  code_b = fetch_otp_from_fly(email_b)
  curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/email_otp/verify",
    "-c", jar_b, "-b", jar_b, *hdrs,
    "-H", "Content-Type: application/json",
    "--data-binary", { email: email_b, code: code_b }.to_json
  )
  curl_post_json(
    "-X", "DELETE", "#{BASE}/shop/api/session",
    "-c", jar_b, "-b", jar_b, *hdrs,
    "-H", "Content-Type: application/json",
    "--data-binary", { refresh_token: refresh_a }.to_json
  )
  refresh_body, refresh_http = curl_post_json(
    "-X", "POST", "#{BASE}/shop/api/session/refresh",
    "-c", jar_a, "-b", jar_a, *hdrs,
    "-H", "Content-Type: application/json",
    "--data-binary", { refresh_token: refresh_a }.to_json
  )
  checks << {
    id: "S3_session_destroy_scoped_refresh",
    pass: refresh_http == 200 && refresh_body["refresh_token"].to_s != "",
    refresh_http: refresh_http,
    note: "B logout with A refresh_token must not revoke A"
  }

  # categories public + rate limit (61st → 429)
  cat_ok = 0
  cat_429 = false
  62.times do |i|
    http = curl_http("#{BASE}/shop/api/categories?tenant_id=#{TENANT_ID}")
    if http == 200
      cat_ok += 1
    elsif http == 429
      cat_429 = true
      break if i >= 60
    end
  end
  checks << {
    id: "S4_categories_rate_limit",
    pass: cat_ok >= 60 && cat_429,
    ok_before_throttle: cat_ok,
    throttled: cat_429
  }

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
