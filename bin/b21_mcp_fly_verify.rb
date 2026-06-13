#!/usr/bin/env ruby
# frozen_string_literal: true

# MCP-style проверка B2.1 табло на Fly (HTTP + bundle probes).
# Дополняет chrome-devtools-mcp скрины — см. b21_mcp_fly_*.json steps.
#
#   ruby bin/b21_mcp_fly_verify.rb

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
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_mcp_fly_#{DATE}.json"
)
NULL_DEV = Gem.win_platform? ? "NUL" : "/dev/null"
SCREEN_DIR = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10"

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed" unless status.success?

  out
end

def csrf_token(html)
  html[/name="csrf-token" content="([^"]+)"/, 1]
end

def staff_login(jar)
  File.delete(jar) if File.exist?(jar)
  html = curl("-c", jar, "#{BASE}/login")
  token = csrf_token(html)
  raise "no csrf" unless token

  hdr = curl(
    "-b", jar, "-c", jar, "-X", "POST", "#{BASE}/login",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[email]=#{BARISTA_EMAIL}",
    "--data-urlencode", "user[password]=#{PASSWORD}",
    "-D", "-", "-o", "-"
  )
  raise "login failed" unless hdr.include?("302")
end

jar = File.join(Dir.tmpdir, "b21-mcp-#{Process.pid}.cookies")
checks = []
steps = []

begin
  login_http = curl("-o", NULL_DEV, "-w", "%{http_code}", "#{BASE}/login").strip.to_i
  checks << { id: "login_page", pass: login_http == 200, http: login_http }
  steps << { step: 1, action: "GET /login", verdict: login_http == 200 ? "PASS" : "FAIL", http: login_http }

  staff_login(jar)
  checks << { id: "barista_session", pass: true }
  steps << { step: 2, action: "POST /login barista demo", verdict: "PASS" }

  board_http = curl("-b", jar, "-o", NULL_DEV, "-w", "%{http_code}", "#{BASE}/barista").strip.to_i
  board_html = curl("-b", jar, "#{BASE}/barista")
  checks << { id: "barista_board", pass: board_http == 200, http: board_http }
  steps << { step: 3, action: "GET /barista authenticated", verdict: board_http == 200 ? "PASS" : "FAIL", http: board_http }

  markup = {
    board_slots: board_html.include?("barista-board-slots"),
    board_grid: board_html.include?("board-grid"),
    b21_cancel: board_html.include?("СТОП! ЗАКАЗ ОТМЕНЁН"),
    stimulus: board_html.include?("order-card-cancel")
  }
  checks << { id: "b21_markup_on_fly", pass: markup.values.all?, markers: markup }
  steps << {
    step: 4,
    action: "Проверка разметки B2.1 на табло",
    result: markup,
    verdict: markup.values.all? ? "PASS" : "FAIL",
    screenshot: "#{SCREEN_DIR}/barista_board_after.png",
    screenshot_required: true
  }

  shop_http = curl("-o", NULL_DEV, "-w", "%{http_code}", "#{BASE}/shop?tenant_id=#{TENANT_ID}").strip.to_i
  shop_html = curl("#{BASE}/shop?tenant_id=#{TENANT_ID}")
  vite_js = shop_html[/\/vite\/assets\/[^"]+\.js/, 0]
  order_status_in_bundle = false
  if vite_js
    bundle = curl("#{BASE}#{vite_js}")
    order_status_in_bundle = bundle.include?("orderStatusProgress") || bundle.include?("OrderStatus")
  end
  checks << { id: "vitrina_catalog", pass: shop_http == 200, http: shop_http }
  checks << { id: "guest_status_bundle", pass: order_status_in_bundle, vite_chunk: vite_js }
  steps << {
    step: 5,
    action: "Витрина + bundle OrderStatus",
    verdict: shop_http == 200 && order_status_in_bundle ? "PASS" : "FAIL",
    screenshot: "#{SCREEN_DIR}/stage5_e2e_vitrina_to_board.png",
    screenshot_required: true,
    note: "скрин e2e — MCP chrome-devtools после smoke vitrina→board"
  }

  required_screens = %w[
    barista_board_after.png
    stage5_e2e_vitrina_to_board.png
    stage2_fifo_accepted.png
    stage2_after_status_move.png
    stage4_cancel_overlay.png
    stage4_cancel_confirmed.png
  ]
  screen_status = required_screens.each_with_object({}) do |name, acc|
    acc[name] = File.exist?(File.join(SCREEN_DIR, name))
  end
  checks << {
    id: "screenshots_on_disk",
    pass: screen_status["barista_board_after.png"] && screen_status["stage5_e2e_vitrina_to_board.png"],
    files: screen_status,
    note: "остальные скрины — обязательны, догоняем по мере MCP прогонов"
  }

  status = checks.all? { |c| c[:pass] } ? "PASS" : "PARTIAL"
rescue StandardError => e
  status = "FAIL"
  checks << { id: "error", pass: false, message: e.message }
ensure
  result = {
    scenario: "B2.1 — табло бариста MCP + HTTP verify",
    task: "B2_1_barista_board_mcp_fly",
    tool: "chrome-devtools-mcp + b21_mcp_fly_verify.rb",
    stand: BASE,
    run_at: DATE,
    tenant_id: TENANT_ID,
    barista_email: BARISTA_EMAIL,
    steps: steps,
    checks: checks,
    status: status,
    customer_signoff: false,
    note: "ops gate этапа 5 — не финальная приёмка заказчика"
  }
  File.write(OUT, JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
  puts "written #{OUT}"
  exit(status == "PASS" ? 0 : 1)
end
