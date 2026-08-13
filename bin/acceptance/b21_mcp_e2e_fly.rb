#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 MCP e2e Fly — полный прогон: prep + Playwright + smoke + тесты → JSON.
#   FLY_BIN=flyctl ruby bin/acceptance/b21_mcp_e2e_fly.rb

require "json"
require "open3"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = ENV.fetch(
  "OUT",
  File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_mcp_e2e_#{DATE}.json")
)
SCREEN_DIR = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10"
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")

def run!(cmd, label)
  puts "==> #{label}: #{cmd}"
  system(cmd) || raise("#{label} failed")
end

def run_capture(cmd)
  out, status = Open3.capture2e(cmd)
  [ out, status.success? ]
end

checks = []
stand = {}

# --- Подготовка стенда ---
whoami, ok = run_capture("#{FLY_BIN} auth whoami 2>&1")
checks << { id: "flyctl_auth", pass: ok && !whoami.strip.empty?, whoami: whoami.strip }
raise "flyctl auth login required" unless checks.last[:pass]

stand = {
  base: ENV.fetch("BASE", "https://coffeeos.fly.dev"),
  tenant_id: ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789"),
  barista_email: ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local"),
  screen_dir: SCREEN_DIR,
  deploy_note: "пользователь: deploy develop выполнен"
}
checks << { id: "stand_constants", pass: true, **stand }

Dir.chdir(ROOT) do
  run!("FLY_BIN=#{FLY_BIN} ruby bin/acceptance/b21_mcp_e2e_prep.rb", "e2e prep")
  prep = JSON.parse(File.read("tmp/b21_mcp_e2e_prep.json"))
  checks << {
    id: "demo_shift_and_order",
    pass: prep["order_id"].to_s != "",
    order_id: prep["order_id"],
    order_dom_id: prep["order_dom_id"]
  }

  playwright_ok = system("node bin/acceptance/b21_mcp_e2e_fly.mjs")
  e2e_steps = JSON.parse(File.read("tmp/b21_mcp_e2e_steps.json"))
  checks << { id: "playwright_e2e", pass: playwright_ok && e2e_steps["status"] == "PASS", steps: e2e_steps["steps"] }

  smoke_ok = system("FLY_BIN=#{FLY_BIN} ruby bin/acceptance/b21_barista_board_fly_smoke.rb")
  smoke_path = Dir.glob("docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_fly_smoke_*.json").max
  smoke = JSON.parse(File.read(smoke_path))
  checks << {
    id: "fly_smoke",
    pass: smoke_ok && smoke["status"] == "PASS",
    artifact: File.basename(smoke_path || "b21_fly_smoke_#{DATE}.json")
  }

  mcp_ok = system("ruby bin/acceptance/b21_mcp_fly_verify.rb")
  mcp_path = Dir.glob("docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_mcp_fly_*.json").max
  mcp = JSON.parse(File.read(mcp_path))
  checks << { id: "mcp_fly_verify", pass: mcp_ok, status: mcp["status"], artifact: File.basename(mcp_path.to_s) }

  guest_ok = system("bin/rails test test/integration/b21_guest_notify_test.rb")
  checks << { id: "b21_guest_notify_test", pass: guest_ok }

  subset_ok = system(
    "bin/rails test test/services/barista/board_orders_query_test.rb " \
    "test/integration/barista_tablet_regression_test.rb:185"
  )
  checks << { id: "b21_board_subset", pass: subset_ok }

  screens = %w[
    stage5_e2e_vitrina_checkout.png stage5_e2e_vitrina_to_board.png
    stage5_e2e_barista_preparing.png stage5_e2e_barista_ready.png
    stage5_e2e_guest_preparing.png stage5_e2e_guest_ready.png
    stage3_guest_preparing.png stage3_guest_ready.png
  ].each_with_object({}) { |f, h| h[f] = File.exist?(File.join(SCREEN_DIR, f)) }
  checks << { id: "screenshots_on_disk", pass: screens.values.all?, files: screens }
end

status = checks.all? { |c| c[:pass] } ? "PASS" : "FAIL"

result = {
  scenario: "B2.1 MCP e2e — витрина → бариста (UI) → гость (WS)",
  task: "B2_1_mcp_e2e_fly",
  run_at: DATE,
  stand: stand,
  order_id: (JSON.parse(File.read(File.join(ROOT, "tmp/b21_mcp_e2e_prep.json"))) rescue {})["order_id"],
  e2e_steps: (JSON.parse(File.read(File.join(ROOT, "tmp/b21_mcp_e2e_steps.json"))) rescue {})["steps"],
  checks: checks,
  status: status,
  customer_signoff: false
}

File.write(OUT, JSON.pretty_generate(result))
puts JSON.pretty_generate(result)
puts "written #{OUT}"
exit(status == "PASS" ? 0 : 1)
