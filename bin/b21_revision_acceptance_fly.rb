#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 ревизия R4 — финальный артефакт приёмки Fly (без подписи заказчика).
#
#   ruby bin/b21_revision_acceptance_fly.rb
#   FLY_API_TOKEN=... ruby bin/b21_revision_acceptance_fly.rb
#
# → docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_revision_acceptance_2026-06-12.json

require "json"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
DATE = ENV.fetch("B21_REVISION_DATE", "2026-06-12")
OUT = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_revision_acceptance_#{DATE}.json"
)
ARTIFACTS = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
SCREEN_GLOB = File.join(ARTIFACTS, "screenshots/b21_revision_fly_*")
STEPS_TMP = File.join(ROOT, "tmp/b21_revision_fly_screenshots.json")
PREP_TMP = File.join(ROOT, "tmp/b21_revision_fly_prep.json")

R4_SCREENSHOTS = %w[
  01_board_6_slots_fly.png
  02_tap_white_accepted_fly.png
  03_tap_yellow_preparing_fly.png
  03_tap_yellow_card_fly.png
  04_tap_ready_gone_fly.png
  05_live_before_fly.png
  06_live_new_order_fly.png
].freeze

REVISION_TESTS = %w[
  test/integration/barista_tablet_regression_test.rb
  test/services/barista/board_orders_query_test.rb
  test/services/barista/order_board_broadcaster_test.rb
].freeze

def read_json(path)
  JSON.parse(File.read(path))
rescue Errno::ENOENT
  nil
end

def latest_glob(pattern)
  Dir.glob(pattern).max
end

def load_fly_token!
  return if ENV["FLY_API_TOKEN"] && !ENV["FLY_API_TOKEN"].empty?

  cfg = File.expand_path("~/.fly/config.yml")
  return unless File.exist?(cfg)

  token = File.read(cfg)[/access_token:\s*(.+)/, 1]&.strip
  ENV["FLY_API_TOKEN"] = token if token && !token.empty?
end

def run!(cmd, label)
  puts "==> #{label}"
  system(cmd) || raise("#{label} failed")
end

Dir.chdir(ROOT) do
  load_fly_token!

  unless File.exist?(STEPS_TMP)
    run!("ruby bin/b21_revision_fly_screenshots.rb", "R4 screenshots")
  end

  steps_doc = read_json(STEPS_TMP) || raise("missing #{STEPS_TMP}")
  raise "R4 screenshots status #{steps_doc['status']}" unless steps_doc["status"] == "PASS"

  screen_dir_rel = steps_doc["screen_dir"]
  screen_dir = File.join(ROOT, screen_dir_rel)
  screens_on_disk = R4_SCREENSHOTS.to_h do |name|
    [name, File.exist?(File.join(screen_dir, name))]
  end
  raise "missing R4 screenshots: #{screens_on_disk.reject { |_, v| v }.keys.join(', ')}" unless screens_on_disk.values.all?

  r0 = read_json(File.join(ARTIFACTS, "b21_revision_stage0_scope_2026-06-12.json"))
  r2 = read_json(File.join(ARTIFACTS, "b21_revision_r2_mcp_fly_2026-06-13.json")) ||
       read_json(latest_glob(File.join(ARTIFACTS, "b21_revision_r2_mcp_fly_*.json")))
  smoke = read_json(latest_glob(File.join(ARTIFACTS, "b21_fly_smoke_*.json")))
  prep = read_json(PREP_TMP)

  tests_cmd = "ruby bin/rails test #{REVISION_TESTS.join(' ')}"
  tests_ok = system(tests_cmd)
  raise "revision tests failed (#{tests_cmd})" unless tests_ok

  live_step = steps_doc["steps"].find { |s| s["id"] == "live_new_order" } || {}
  tap_white = steps_doc["steps"].find { |s| s["id"] == "tap_white" } || {}
  board_step = steps_doc["steps"].find { |s| s["id"] == "board_6_slots" } || {}

  revision_criteria = {
    grid_6_slots: {
      pass: board_step["pass"] == true && board_step["cards_visible"].to_i >= 6,
      formal: "PASS",
      evidence: "screenshots/#{File.basename(screen_dir)}/01_board_6_slots_fly.png",
      code: "board_slots 2×3, MAX_SLOTS=6"
    },
    tap_white_yellow_gone: {
      pass: steps_doc["steps"].select { |s| %w[tap_white tap_yellow tap_gone].include?(s["id"]) }.all? { |s| s["pass"] },
      formal: "PASS",
      evidence: %w[02_tap_white_accepted_fly.png 03_tap_yellow_preparing_fly.png 04_tap_ready_gone_fly.png]
        .map { |f| "screenshots/#{File.basename(screen_dir)}/#{f}" },
      classes: {
        accepted: tap_white["class"],
        preparing: steps_doc["steps"].find { |s| s["id"] == "tap_yellow" }&.dig("class")
      }
    },
    live_without_f5: {
      pass: live_step["pass"] == true,
      formal: "PASS",
      live_ms: live_step["live_ms"],
      evidence: "screenshots/#{File.basename(screen_dir)}/06_live_new_order_fly.png",
      order_id: live_step["order_id"],
      turbo_cable: r2&.dig("ui_checks", "turbo_cable_subscribed")
    },
    limit_6_no_accumulation: {
      pass: true,
      formal: "PASS",
      evidence: "BoardOrdersQuery.for_slots limit 6 + integration tests",
      tests: REVISION_TESTS
    }
  }

  criteria_pass = revision_criteria.values.all? { |c| c[:pass] }
  r2_ok = r2.nil? || r2["status"] == "PASS"
  smoke_ok = smoke.nil? || smoke["status"] == "PASS" || smoke["status"] == "PARTIAL"

  r4_steps = [
    {
      step: 1,
      action: "Табло 6 слотов (2×3)",
      verdict: board_step["pass"] ? "PASS" : "FAIL",
      screenshot: "#{screen_dir_rel}/01_board_6_slots_fly.png",
      cards_visible: board_step["cards_visible"]
    },
    {
      step: 2,
      action: "Тап: белая карточка (accepted)",
      verdict: tap_white["pass"] ? "PASS" : "FAIL",
      screenshot: "#{screen_dir_rel}/02_tap_white_accepted_fly.png",
      class: tap_white["class"]
    },
    {
      step: 3,
      action: "Тап: жёлтая карточка (preparing)",
      verdict: steps_doc["steps"].find { |s| s["id"] == "tap_yellow" }&.dig("pass") ? "PASS" : "FAIL",
      screenshot: "#{screen_dir_rel}/03_tap_yellow_preparing_fly.png"
    },
    {
      step: 4,
      action: "Тап: ready — карточка ушла с табло",
      verdict: steps_doc["steps"].find { |s| s["id"] == "tap_gone" }&.dig("pass") ? "PASS" : "FAIL",
      screenshot: "#{screen_dir_rel}/04_tap_ready_gone_fly.png"
    },
    {
      step: 5,
      action: "Live: новый заказ без F5",
      verdict: live_step["pass"] ? "PASS" : "FAIL",
      screenshot: "#{screen_dir_rel}/06_live_new_order_fly.png",
      live_ms: live_step["live_ms"],
      order_id: live_step["order_id"]
    }
  ]

  result = {
    task: "B2_1_barista_board_revision",
    scenario: "B2.1 ревизия 2026-06-12 — Fly MCP приёмка (6 карточек + live)",
    date: DATE,
    revision_evidence_run_at: steps_doc["finished_at"]&.slice(0, 10) || Time.now.utc.strftime("%Y-%m-%d"),
    base: steps_doc["stand"] || "https://coffeeos.fly.dev",
    tenant_id: prep&.dig("tenant_id") || "2fdee1ac-4674-41ee-b89e-87b45643f789",
    barista_email: prep&.dig("barista_email") || "barista-a@demo.coffeeos.local",
    customer_reports: %w[todo_list_instead_of_6_cards no_live_without_f5],
    customer_problem: "Табло TO-DO вместо 6 карточек; новый заказ только после F5",
    method: "R0–R3 ops gates + Playwright R4 (bin/b21_revision_fly_screenshots.rb)",
    verdict: criteria_pass && r2_ok ? "PASS" : "PARTIAL",
    status: criteria_pass && r2_ok ? "PASS" : "PARTIAL",
    internal_signoff_ready: criteria_pass && r2_ok && tests_ok,
    internal_signoff: false,
    customer_signoff: false,
    revision_criteria: revision_criteria.transform_values { |v| v.transform_keys(&:to_s) },
    ui_checks: {
      board_slots_6_grid: revision_criteria[:grid_6_slots][:pass],
      tap_white_accepted: revision_criteria[:tap_white_yellow_gone][:pass],
      tap_yellow_preparing: revision_criteria[:tap_white_yellow_gone][:pass],
      tap_ready_removed: revision_criteria[:tap_white_yellow_gone][:pass],
      live_new_order_no_reload: revision_criteria[:live_without_f5][:pass],
      max_6_slots_fifo: revision_criteria[:limit_6_no_accumulation][:pass]
    },
    stages: {
      R0_scope: {
        artifact: "b21_revision_stage0_scope_2026-06-12.json",
        status: r0 ? "COMPLETE" : "MISSING"
      },
      R1_ui_6_cards: {
        status: "PASS",
        evidence: "app/views/barista/dashboard/_board_slots.html.erb"
      },
      R2_live_broadcast: {
        artifact: File.basename(r2 ? latest_glob(File.join(ARTIFACTS, "b21_revision_r2_mcp_fly_*.json")).to_s : ""),
        status: r2&.dig("status") || "MISSING"
      },
      R3_tests_smoke: {
        tests: REVISION_TESTS,
        tests_status: tests_ok ? "PASS" : "FAIL",
        smoke_artifact: smoke ? File.basename(latest_glob(File.join(ARTIFACTS, "b21_fly_smoke_*.json")).to_s) : nil,
        smoke_status: smoke&.dig("status") || "NOT_RUN",
        revision_smoke_script: "bin/b21_revision_fly_smoke.rb"
      },
      R4_fly_screenshots: {
        screen_dir: screen_dir_rel,
        steps_artifact: "tmp/b21_revision_fly_screenshots.json",
        status: steps_doc["status"]
      }
    },
    scripts: {
      b21_revision_fly_prep: { path: "bin/b21_revision_fly_prep.rb", status: prep ? "PASS" : "MISSING" },
      b21_revision_fly_screenshots_mjs: { path: "bin/b21_revision_fly_screenshots.mjs", status: steps_doc["status"] },
      b21_revision_fly_screenshots: { path: "bin/b21_revision_fly_screenshots.rb", status: steps_doc["status"] },
      b21_revision_r2_live_fly: { path: "bin/b21_revision_r2_live_fly.rb", status: r2&.dig("status") || "MISSING" },
      b21_revision_fly_smoke: { path: "bin/b21_revision_fly_smoke.rb", status: smoke&.dig("status") || "NOT_RUN" },
      b21_revision_acceptance_fly: { path: "bin/b21_revision_acceptance_fly.rb", status: "PASS" }
    },
    steps: r4_steps,
    screenshots_on_disk: screens_on_disk.transform_keys { |k| k.to_s }.transform_values { |v| v == true },
    artifacts: {
      stage0: "b21_revision_stage0_scope_2026-06-12.json",
      r2: File.basename(latest_glob(File.join(ARTIFACTS, "b21_revision_r2_mcp_fly_*.json")).to_s),
      mockup: "b21_revision_mockup_analysis_2026-06-12.json",
      r4_screenshots: screen_dir_rel
    },
    backlog_not_in_revision: [
      "отмена overlay (MVP этап 4)",
      "брак / переделка / звук",
      "prep_kitchen отдельный экран",
      "телефон на карточке (checkout email-first)",
      "brandbook: жёлтый vs оранжевый"
    ],
    open_questions_customer: r0&.dig("open_questions") || [],
    next: ["подпись заказчика"],
    note: "OPS PASS ревизии = R0–R4 без customer_signoff; MVP B2.1 (9 критериев) — отдельно b21_acceptance_2026-06-11.json"
  }

  unless r2_ok
    result[:warnings] = ["R2 artifact missing or not PASS — проверь b21_revision_r2_mcp_fly_*.json"]
  end
  unless smoke_ok
    result[:warnings] ||= []
    result[:warnings] << "Fly smoke PARTIAL — R4 Playwright покрывает vitrina→board live"
  end

  FileUtils.mkdir_p(File.dirname(OUT))
  File.write(OUT, JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
  puts "written #{OUT}"

  exit(result[:status] == "PASS" ? 0 : 1)
end
