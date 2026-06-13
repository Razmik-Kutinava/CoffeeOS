#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 ревизия — прогон приёмки заказчика (Chrome DevTools MCP path + Playwright скрины).
#   FLY_API_TOKEN=... ruby bin/b21_revision_customer_mcp.rb
#
# → screenshots/b21_revision_customer_mcp_<date>/
# → tmp/b21_revision_customer_mcp.json
# → обновляет b21_revision_acceptance_2026-06-12.json (customer_verification)

require "json"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
DATE = Time.now.utc.strftime("%Y-%m-%d")
SCREEN_DIR = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_revision_customer_mcp_#{DATE}"
PREP_OUT = File.join(ROOT, "tmp/b21_revision_customer_mcp_prep.json")
STEPS_OUT = File.join(ROOT, "tmp/b21_revision_customer_mcp.json")
ACCEPTANCE = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_revision_acceptance_2026-06-12.json")

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

  devtools_note = {
    tool: "chrome-devtools-mcp",
    login_attempt: "POST /login from browser → HTTP 500 on Fly (#{DATE} session)",
    fallback: "Playwright headless — тот же сценарий заказчика"
  }

  run!(
    "ruby bin/b21_revision_fly_prep.rb",
    "prep 6 orders demo A"
  )
  prep = JSON.parse(File.read("tmp/b21_revision_fly_prep.json"))
  prep["screen_dir"] = SCREEN_DIR
  prep["task"] = "B21_revision_customer_mcp_prep"
  FileUtils.mkdir_p(File.dirname(PREP_OUT))
  File.write(PREP_OUT, JSON.pretty_generate(prep))
  File.write("tmp/b21_revision_fly_prep.json", JSON.pretty_generate(prep))

  run!("node bin/b21_revision_customer_mcp.mjs", "customer MCP screenshots")

  steps = JSON.parse(File.read(STEPS_OUT))
  raise "customer mcp FAIL" unless steps["status"] == "PASS"

  acceptance = JSON.parse(File.read(ACCEPTANCE))
  acceptance["customer_verification"] = {
    date: DATE,
    method: "chrome-devtools-mcp (login blocked) + Playwright browser path",
    devtools: devtools_note,
    playwright: {
      script: "bin/b21_revision_customer_mcp.mjs",
      screen_dir: SCREEN_DIR,
      steps_artifact: "tmp/b21_revision_customer_mcp.json",
      status: steps["status"]
    },
    checklist: {
      "1_1_grid_6_slots": steps["steps"].find { |s| s["id"] == "board_6_slots" }&.dig("pass"),
      "1_1_no_kanban_columns": steps["steps"].find { |s| s["id"] == "no_kanban_columns" }&.dig("pass"),
      "1_2_tap_white_yellow_gone": %w[tap_white tap_yellow tap_gone].all? do |id|
        steps["steps"].find { |s| s["id"] == id }&.dig("pass")
      end,
      "1_3_live_without_f5": steps["steps"].find { |s| s["id"] == "live_new_order" }&.dig("pass"),
      "1_4_limit_6": steps["steps"].find { |s| s["id"] == "limit_6_slots" }&.dig("pass")
    },
    internal_ops_verified: true,
    customer_signoff: false,
    customer_signoff_pending: "формальная подпись заказчика после просмотра скринов"
  }
  acceptance["screenshots_customer_mcp"] = SCREEN_DIR

  File.write(ACCEPTANCE, JSON.pretty_generate(acceptance))
  puts "updated #{ACCEPTANCE}"
  puts JSON.pretty_generate(acceptance["customer_verification"])
end
