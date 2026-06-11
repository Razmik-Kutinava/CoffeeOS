#!/usr/bin/env ruby
# frozen_string_literal: true

# Обновить статус заказа из tmp/b21_stage3_guest_prep.json (barista cookie).
#   ruby bin/b21_stage3_barista_status.rb preparing|ready

require "json"
require "open3"

PREP = JSON.parse(File.read("tmp/b21_stage3_guest_prep.json"))
BASE = PREP["base"]
BARISTA_EMAIL = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
ORDER_ID = PREP["order_id"]
STATUS = ARGV.fetch(0) { raise "usage: b21_stage3_barista_status.rb preparing|ready" }
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"
JAR = PREP["barista_jar"]

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed" unless status.success?

  out
end

def csrf_token(html)
  html[/name="csrf-token" content="([^"]+)"/, 1]
end

def login_barista!(jar)
  File.delete(jar) if File.exist?(jar)
  login_html = curl("-c", jar, "#{BASE}/login")
  token = csrf_token(login_html)
  raise "no csrf on login" if token.nil? || token.empty?

  hdr = curl(
    "-b", jar, "-c", jar, "-X", "POST", "#{BASE}/login",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[email]=#{BARISTA_EMAIL}",
    "--data-urlencode", "user[password]=#{PASSWORD}",
    "-D", "-", "-o", "-"
  )
  raise "barista login failed" unless hdr.include?("302")
end

login_barista!(JAR)
board = curl("-b", JAR, "#{BASE}/barista")
token = board[/name="csrf-token" content="([^"]+)"/, 1]
raise "no csrf" if token.nil? || token.empty?

# Без открытой смены PATCH update_status редиректит, но статус не меняется.
unless board.include?("Смена открыта") || board.include?("opened_at") || board.include?("count-new")
  curl(
    "-b", JAR, "-c", JAR,
    "-X", "POST", "#{BASE}/barista/shift/open",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "opening_cash=0",
    "-o", NULL_DEV
  )
  board = curl("-b", JAR, "#{BASE}/barista")
  token = board[/name="csrf-token" content="([^"]+)"/, 1]
  raise "no csrf after shift open" if token.nil? || token.empty?
end

hdr = curl(
  "-b", JAR, "-c", JAR,
  "-X", "PATCH", "#{BASE}/barista/orders/#{ORDER_ID}/update_status",
  "--data-urlencode", "authenticity_token=#{token}",
  "--data-urlencode", "status=#{STATUS}",
  "-D", "-", "-o", NULL_DEV
)
unless hdr.include?("302") || hdr.include?("200")
  warn hdr
  raise "barista PATCH failed for #{STATUS}"
end
if hdr.include?("location: /login")
  raise "barista session lost after PATCH"
end
puts "order #{ORDER_ID} -> #{STATUS}"
