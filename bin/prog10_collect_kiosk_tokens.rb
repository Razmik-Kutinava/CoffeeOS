#!/usr/bin/env ruby
# frozen_string_literal: true

# Собрать/создать киоски на 9 точках (UK login + open_as_manager). Токены → OUT (не коммитить).
# Usage: ruby bin/prog10_collect_kiosk_tokens.rb [/tmp/prog10_kiosk_tokens.json]

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
JAR = "/tmp/prog10-admin.cookies"
OUT = ARGV[0] || "/tmp/prog10_kiosk_tokens.json"
EMAIL = ENV.fetch("UK_EMAIL", "uk@demo.coffeeos.local")
PASSWORD = ENV.fetch("UK_PASSWORD", "demo123456")

TENANTS = {
  "2fdee1ac-4674-41ee-b89e-87b45643f789" => "demo-a",
  "655aaccb-004a-4bb9-a50a-ce618854dda3" => "demo-b",
  "d47165db-81c9-4e9d-bc50-e37fe610d86c" => "demo-prep",
  "1c064640-4301-4435-8ded-c92fb075e9cc" => "alpha-p1",
  "edf8a0a9-38e7-4049-b9c6-3e08c6c23a76" => "alpha-p2",
  "d29fcf3a-da72-4a95-9683-9cfa71a2d865" => "alpha-p3",
  "03a4d457-e16f-4998-b764-69b3de083732" => "beta-p1",
  "628a937b-f4e2-43b7-bd7f-9fa44f031460" => "beta-p2",
  "b57c2a88-91a5-481e-b44f-29e29c77cfb5" => "beta-p3"
}.freeze

def curl(*args)
  out, status = Open3.capture2("curl", "-s", "-c", JAR, "-b", JAR, *args)
  raise "curl failed: #{args.first(5).join(' ')}" unless status
  out
end

def csrf(html)
  html[/name="csrf-token" content="([^"]+)"/, 1] ||
    html[/authenticity_token" value="([^"]+)"/, 1]
end

def parse_kiosk_tokens(html)
  tokens = {}
  html.scan(/token:\s*([a-f0-9]{48})/i) { |m| tokens[m[0]] = true }
  html.scan(/token:\s*([a-f0-9]+)/i).flatten.uniq
end

def find_prog10_token(html, label)
  # Prefer row with Prog10 Kiosk and label
  if html.include?("Prog10 Kiosk")
    parse_kiosk_tokens(html).each do |tok|
      return tok if html.include?(tok) && html.include?("Prog10 Kiosk")
    end
  end
  parse_kiosk_tokens(html).first
end

File.delete(JAR) if File.exist?(JAR)
login_html = curl("#{BASE}/login")
token = csrf(login_html)
raise "no csrf on login" unless token

curl("-X", "POST", "#{BASE}/login",
  "-H", "Content-Type: application/x-www-form-urlencoded",
  "--data-urlencode", "authenticity_token=#{token}",
  "--data-urlencode", "user[email]=#{EMAIL}",
  "--data-urlencode", "user[password]=#{PASSWORD}",
  "-o", "/dev/null", "-w", "%{http_code}")

result = {}
TENANTS.each do |tid, label|
  dash = curl("#{BASE}/admin")
  tok = csrf(dash)
  curl("-X", "POST", "#{BASE}/admin/tenants/#{tid}/open_as_manager",
    "-H", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "authenticity_token=#{tok}",
    "-o", "/dev/null")
  devices_html = curl("#{BASE}/manager/devices")
  kiosk_token = find_prog10_token(devices_html, label)
  unless kiosk_token
    tok2 = csrf(devices_html)
    name = "Prog10 Kiosk #{label}"
    after = curl("-X", "POST", "#{BASE}/manager/devices/kiosk",
      "-H", "Content-Type: application/x-www-form-urlencoded",
      "--data-urlencode", "authenticity_token=#{tok2}",
      "--data-urlencode", "device[name]=#{name}")
    kiosk_token = parse_kiosk_tokens(after).first || parse_kiosk_tokens(curl("#{BASE}/manager/devices")).first
    # notice may contain full token
    kiosk_token = after[/Токен:\s*([a-f0-9]+)/i, 1] || kiosk_token
  end
  result[tid] = kiosk_token
  puts "#{label} #{tid[0, 8]}… token=#{kiosk_token ? kiosk_token[0, 12] : 'MISSING'}"
  sleep 1
end

File.write(OUT, JSON.pretty_generate(result))
missing = result.values.any?(&:nil?) || result.values.any?(&:empty?)
exit(missing ? 1 : 0)
