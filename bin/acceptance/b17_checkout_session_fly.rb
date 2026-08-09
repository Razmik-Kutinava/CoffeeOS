#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.7 баг-3 — checkout OTP: prep Fly (verify email в БД) + JSON для MCP прогона «сессия истекла».
#
#   FLY_BIN=flyctl ruby bin/acceptance/b17_checkout_session_fly.rb
#   node bin/acceptance/b17_checkout_session_mcp.mjs
#
# → tmp/b17_checkout_session_prep.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"
require "uri"

ROOT = File.expand_path("../..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B17_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
OUT = ENV.fetch("OUT", File.join(ROOT, "tmp/b17_checkout_session_prep.json"))
DATE = Time.now.utc.strftime("%Y-%m-%d")
ARTIFACT = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b17_checkout_session_#{DATE}.json"
)
SCREEN_DIR = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b17_checkout_session_#{DATE}"
)

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

def curl_post_json(url, jar, headers:, body:)
  raw = curl("-c", jar, "-b", jar, "-X", "POST", url,
    *headers.flat_map { |k, v| ["-H", "#{k}: #{v}"] },
    "-d", body.to_json,
    "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [JSON.parse(body_raw), http]
end

def curl_get_json(url, jar, headers:)
  raw = curl("-c", jar, "-b", jar, url,
    *headers.flat_map { |k, v| ["-H", "#{k}: #{v}"] },
    "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [JSON.parse(body_raw), http]
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
  code = [out, err].join.scan(/\b(\d{6})\b/).last&.first
  code unless code == "NONE"
end

load_fly_token!
suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b17-session-#{suffix}@coffeeos.dev"
name = "Session QA"
jar = File.join(Dir.tmpdir, "b17-checkout-#{suffix}.cookies")
FileUtils.mkdir_p(File.dirname(OUT))
FileUtils.mkdir_p(SCREEN_DIR)

api_key = shop_key(TENANT_ID)
headers = {
  "Accept" => "application/json",
  "Content-Type" => "application/json",
  "X-Shop-Tenant" => TENANT_ID,
  "X-Shop-Api-Key" => api_key
}

curl("#{BASE}/shop?tenant_id=#{TENANT_ID}", "-c", jar, "-b", jar, "-o", File::NULL)

send_body, send_http = curl_post_json(
  "#{BASE}/shop/api/email_otp/send?tenant_id=#{TENANT_ID}",
  jar, headers: headers, body: { email: email }
)
raise "send failed #{send_http}: #{send_body}" unless send_http == 200

sleep 2
code = fetch_otp(email)
raise "no otp code from fly" if code.nil? || code.empty?

verify_body, verify_http = curl_post_json(
  "#{BASE}/shop/api/email_otp/verify?tenant_id=#{TENANT_ID}",
  jar, headers: headers, body: { email: email, code: code }
)
raise "verify failed #{verify_http}: #{verify_body}" unless verify_http == 200

status_body, status_http = curl_get_json(
  "#{BASE}/shop/api/email_otp/status?tenant_id=#{TENANT_ID}&email=#{URI.encode_www_form_component(email)}",
  jar, headers: headers
)
raise "status failed #{status_http}: #{status_body}" unless status_http == 200 && status_body["verified"]

prep = {
  task: "B1_7_checkout_session_expired",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  shop_url: "#{BASE}/shop?tenant_id=#{TENANT_ID}",
  checkout_hash: "#/checkout",
  email: email,
  name: name,
  profile_storage_key: "shop_guest_profile:#{TENANT_ID}",
  otp_code: code,
  verified_in_prep: true,
  screen_dir: SCREEN_DIR.sub("#{ROOT}/", "").tr("\\", "/"),
  artifact: ARTIFACT.sub("#{ROOT}/", "").tr("\\", "/")
}

File.write(OUT, JSON.pretty_generate(prep))
puts "Wrote #{OUT}"
puts JSON.pretty_generate(prep)
