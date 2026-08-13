#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 B2-S1 — prep Fly: пустое табло + shop cookies для MCP звука нового заказа.
#
#   FLY_BIN=flyctl ruby bin/acceptance/b21_s1_sound_prep_fly.rb
#   node bin/acceptance/b21_s1_sound_mcp.mjs
#
# → tmp/b21_s1_sound_prep.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"

ROOT = File.expand_path("../..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
BARISTA_EMAIL = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = ENV.fetch("OUT", File.join(ROOT, "tmp/b21_s1_sound_prep.json"))
SCREEN_DIR = ENV.fetch(
  "SCREEN_DIR",
  File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_s1_sound_#{DATE}")
)
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

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
  raise "fly machine list failed — need #{FLY_BIN} auth login" unless status.success?

  machines = JSON.parse(out)
  machine = machines.find { |m| m["state"] == "started" } || machines.first
  machine&.dig("id") || raise("no fly machine")
end

def fly_runner(ruby)
  remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote_cmd)
  combined = [ out, err ].join.strip
  raise "fly runner failed: #{combined}" unless st.success?

  combined
end

def clear_barista_board!
  ruby = [
    "tid = #{TENANT_ID.inspect}",
    "shift = CashShift.find_by(tenant_id: tid, status: 'open')",
    "scope = Barista::BoardOrdersQuery.board_scope(tenant_id: tid, cash_shift: shift || :auto)",
    "scope = scope.where(status: %w[accepted preparing])",
    "count = scope.update_all(status: 'ready', updated_at: Time.current)",
    "puts \"cleared \#{count}\""
  ].join("; ")
  puts "board cleared: #{fly_runner(ruby)}"
end

def fetch_otp_from_fly(email)
  ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
  out, err, = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP,
    "/rails/bin/rails runner #{ruby.inspect}")
  code = [ out, err ].join.scan(/\b(\d{6})\b/).last&.first
  code unless code == "NONE"
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

def shop_checkout!(shop_jar:, api_key:, email:)
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
end

def jar_to_playwright_cookies(jar_path)
  cookies = []
  File.foreach(jar_path) do |line|
    next if line.strip.empty?

    raw = line.chomp
    http_only = false
    if raw.start_with?("#HttpOnly_")
      http_only = true
      raw = raw.delete_prefix("#HttpOnly_")
    elsif raw.start_with?("#")
      next
    end

    parts = raw.split("\t")
    next unless parts.size >= 7

    domain, _flag, path, secure, _expires, name, value = parts
    cookies << {
      name: name,
      value: value,
      domain: domain,
      path: path.empty? ? "/" : path,
      secure: secure == "TRUE",
      httpOnly: http_only
    }
  end
  cookies
end

suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b21-s1-#{suffix}@coffeeos.dev"
shop_jar = File.join(Dir.tmpdir, "b21-s1-shop-#{suffix}.cookies")
barista_jar = File.join(Dir.tmpdir, "b21-s1-barista-#{suffix}.cookies")

load_fly_token!
api_key = shop_key(TENANT_ID)
login_user!(email: BARISTA_EMAIL, jar: barista_jar)
ensure_barista_shift!(barista_jar)
clear_barista_board!

curl("-c", shop_jar, "#{BASE}/shop?tenant_id=#{TENANT_ID}", "-o", NULL_DEV)
shop_checkout!(shop_jar: shop_jar, api_key: api_key, email: email)

products = JSON.parse(curl(
  "#{BASE}/shop/api/products",
  "-H", "X-Shop-Tenant: #{TENANT_ID}",
  "-H", "X-Shop-Api-Key: #{api_key}"
))
product_id = products.dig("data", 0, "id")
raise "no product on tenant" unless product_id

payload = {
  task: "b21_s1_sound_prep",
  date: DATE,
  run_at: Time.now.utc.iso8601,
  base: BASE,
  tenant_id: TENANT_ID,
  barista_email: BARISTA_EMAIL,
  screen_dir: SCREEN_DIR.sub("#{ROOT}/", ""),
  vitrina_email: email,
  api_key: api_key,
  product_id: product_id,
  shop_cookies: jar_to_playwright_cookies(shop_jar),
  guest_base: "#{BASE}/shop?tenant_id=#{TENANT_ID}",
  audio_path: "/audio/barista_new_order.wav"
}

FileUtils.mkdir_p(SCREEN_DIR)
FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
puts "written #{OUT}"
