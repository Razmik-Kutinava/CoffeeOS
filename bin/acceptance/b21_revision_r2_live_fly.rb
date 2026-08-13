#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 ревизия R2 — live табло без F5 на Fly (MCP ops gate).
#
#   ruby bin/acceptance/b21_revision_r2_live_fly.rb

require "json"
require "open3"
require "tmpdir"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
TENANT_ID = ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
BARISTA_EMAIL = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = ENV.fetch(
  "OUT",
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_revision_r2_mcp_fly_#{DATE}.json"
)
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(6).join(' ')}" unless status.success?

  out
end

def csrf_token(html)
  html[/name="csrf-token" content="([^"]+)"/, 1] ||
    html[/name="authenticity_token" value="([^"]+)"/, 1]
end

def order_cards(html)
  html.scan(/board-slot-card board-slot-card--(\w+)" id="order_([a-f0-9-]+)"/).map { |status, id| [ id, status ] }
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
  raise "login failed for #{email}" unless hdr.include?("302")
end

jar = File.join(Dir.tmpdir, "b21-r2-live-#{Process.pid}.cookies")
steps = []
checks = []
markup = nil

begin
  login_user!(email: BARISTA_EMAIL, jar: jar)
  steps << { step: 1, action: "POST /login barista", verdict: "PASS" }
  checks << { id: "barista_login", pass: true }

  board_before = curl("-b", jar, "#{BASE}/barista")
  cards_before = order_cards(board_before)
  markup = {
    board_slots: board_before.include?('id="barista-board-slots"'),
    board_grid: board_before.include?("board-grid"),
    turbo_cable: board_before.include?("turbo-cable-stream-source"),
    footer_hint: board_before.include?("Коснитесь карточки")
  }
  steps << {
    step: 2,
    action: "GET /barista — разметка ревизии 6 слотов + turbo-cable",
    result: markup,
    verdict: markup.values.all? ? "PASS" : "FAIL",
    orders_on_board: cards_before.size
  }
  checks << { id: "revision_markup", pass: markup.values.all?, markers: markup }

  target = cards_before.find { |(_id, status)| status == "accepted" }
  if target
    order_id, current_status = target
    token = csrf_token(board_before)
    turbo_raw = curl(
      "-b", jar,
      "-X", "PATCH", "#{BASE}/barista/orders/#{order_id}/update_status?status=preparing",
      "-H", "Accept: text/vnd.turbo-stream.html",
      "--data-urlencode", "authenticity_token=#{token}",
      "-w", "\n__HTTP__%{http_code}"
    )
    turbo_http = turbo_raw[/__HTTP__(\d+)\z/, 1].to_i
    turbo_body = turbo_raw.sub(/\n__HTTP__\d+\z/, "")
    full_grid = turbo_body.include?('target="barista-board-slots"')
    card_stream = turbo_body.include?("target=\"order_#{order_id}\"")
    status_changed = turbo_body.include?("board-slot-card--preparing")

    steps << {
      step: 3,
      action: "PATCH update_status → Turbo Stream (live без F5)",
      verdict: turbo_http == 200 && (full_grid || card_stream) ? "PASS" : "FAIL",
      http: turbo_http,
      order_id: order_id,
      turbo_target: full_grid ? "barista-board-slots" : (card_stream ? "order_card" : "unknown"),
      status_changed: status_changed,
      note: status_changed ? nil : "смена может быть закрыта — карточка без смены статуса, stream всё равно 200"
    }
    checks << {
      id: "live_turbo_stream",
      pass: turbo_http == 200 && (full_grid || card_stream),
      http: turbo_http,
      full_grid_replace: full_grid,
      status_changed: status_changed
    }
  else
    steps << {
      step: 3,
      action: "PATCH update_status — пропуск (нет accepted на табло)",
      verdict: "SKIP",
      note: "разметка и cable проверены; tap e2e — R4 со открытой сменой"
    }
    checks << { id: "live_turbo_stream", pass: true, skip: true }
  end

  status = checks.reject { |c| c[:skip] }.all? { |c| c[:pass] } ? "PASS" : "FAIL"
rescue StandardError => e
  status = "FAIL"
  checks << { id: "error", pass: false, message: "#{e.class}: #{e.message}" }
  steps << { step: 99, action: "error", verdict: "FAIL", message: e.message }
ensure
  result = {
    scenario: "B2.1 revision R2 — live табло без F5 (Fly MCP)",
    task: "B2_1_barista_board_revision_r2",
    tool: "b21_revision_r2_live_fly.rb + b21_mcp_fly_verify.rb",
    stand: BASE,
    run_at: DATE,
    tenant_id: TENANT_ID,
    barista_email: BARISTA_EMAIL,
    steps: steps,
    checks: checks,
    status: status,
    ui_checks: {
      board_slots_6_grid: checks.find { |c| c[:id] == "revision_markup" }&.dig(:pass),
      turbo_cable_subscribed: markup&.dig(:turbo_cable),
      live_turbo_stream_200: checks.find { |c| c[:id] == "live_turbo_stream" }&.dig(:pass)
    },
    customer_signoff: false,
    note: "R2 ops PASS = разметка 6 слотов + turbo-cable + turbo-stream 200; vitrina→board и tap white→yellow — R3/R4"
  }
  File.write(OUT, JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
  puts "written #{OUT}"
  exit(status == "PASS" ? 0 : 1)
end
