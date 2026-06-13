#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 ревизия — сверка 7 PNG (b21_revision_fly_*) с артефактом приёмки.
#
#   ruby bin/b21_revision_verify_screenshots_json.rb
#
# → docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_revision_screenshots_json_verify_YYYY-MM-DD.json
# → обновляет блок screenshots_json_verification в b21_revision_acceptance_*.json

require "json"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
ARTIFACTS = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
ACCEPTANCE_DATE = ENV.fetch("B21_REVISION_DATE", "2026-06-12")
ACCEPTANCE = File.join(ARTIFACTS, "b21_revision_acceptance_#{ACCEPTANCE_DATE}.json")
SCREEN_DIR = File.join(ARTIFACTS, "screenshots/b21_revision_fly_2026-06-13")

R4_PNG = %w[
  01_board_6_slots_fly.png
  02_tap_white_accepted_fly.png
  03_tap_yellow_preparing_fly.png
  03_tap_yellow_card_fly.png
  04_tap_ready_gone_fly.png
  05_live_before_fly.png
  06_live_new_order_fly.png
].freeze

UI_CHECKS = %w[
  board_slots_6_grid
  tap_white_accepted
  tap_yellow_preparing
  tap_ready_removed
  live_new_order_no_reload
  max_6_slots_fifo
].freeze

def read_json(path)
  JSON.parse(File.read(path))
rescue Errno::ENOENT
  nil
end

Dir.chdir(ROOT) do
  run_at = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  run_date = run_at.slice(0, 10)

  png_on_disk = R4_PNG.to_h do |name|
    path = File.join(SCREEN_DIR, name)
    [name, File.file?(path)]
  end
  png_missing = png_on_disk.reject { |_, ok| ok }.keys
  png_ok = png_missing.empty?

  acceptance = read_json(ACCEPTANCE)
  unless acceptance
    warn "missing #{ACCEPTANCE}"
    exit 1
  end

  verdict_ok = acceptance["verdict"] == "PASS"
  status_ok = acceptance["status"] == "PASS"

  ui = acceptance["ui_checks"] || {}
  ui_results = UI_CHECKS.to_h { |k| [k, ui[k] == true] }
  ui_missing = UI_CHECKS - ui.keys
  ui_false = ui_results.reject { |_, v| v }.keys
  ui_ok = ui_missing.empty? && ui_false.empty?

  json_screens = acceptance["screenshots_on_disk"] || {}
  json_screens_match = R4_PNG.all? { |name| json_screens[name] == true }

  mismatches = []
  mismatches << "PNG missing on disk: #{png_missing.join(', ')}" unless png_ok
  mismatches << "verdict != PASS (#{acceptance['verdict'].inspect})" unless verdict_ok
  mismatches << "status != PASS (#{acceptance['status'].inspect})" unless status_ok
  mismatches << "ui_checks missing keys: #{ui_missing.join(', ')}" unless ui_missing.empty?
  mismatches << "ui_checks false: #{ui_false.join(', ')}" unless ui_false.empty?
  unless json_screens_match
    bad = R4_PNG.reject { |name| json_screens[name] == true }
    mismatches << "screenshots_on_disk in JSON не совпадает с диском: #{bad.join(', ')}"
  end

  pass = mismatches.empty?

  verification = {
    task: "B2_1_barista_board_revision",
    check: "screenshots_and_json_reconciliation",
    date: run_date,
    verified_at: run_at,
    screen_dir: "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_revision_fly_2026-06-13",
    acceptance_artifact: "b21_revision_acceptance_#{ACCEPTANCE_DATE}.json",
    verdict: pass ? "PASS" : "FAIL",
    status: pass ? "PASS" : "FAIL",
    checks: {
      png_7_on_disk: {
        pass: png_ok,
        expected: R4_PNG,
        on_disk: png_on_disk
      },
      json_verdict_pass: {
        pass: verdict_ok,
        value: acceptance["verdict"]
      },
      json_status_pass: {
        pass: status_ok,
        value: acceptance["status"]
      },
      json_ui_checks_all_true: {
        pass: ui_ok,
        expected: UI_CHECKS,
        values: ui.slice(*UI_CHECKS),
        false_keys: ui_false,
        missing_keys: ui_missing
      },
      json_screenshots_on_disk_matches: {
        pass: json_screens_match,
        values: json_screens.slice(*R4_PNG)
      }
    },
    comment: pass ? "Все 7 PNG на месте; JSON verdict/status PASS; ui_checks — все true." : mismatches.join("; ")
  }

  verify_out = File.join(ARTIFACTS, "b21_revision_screenshots_json_verify_#{run_date}.json")
  File.write(verify_out, JSON.pretty_generate(verification))

  acceptance["screenshots_json_verification"] = verification
  File.write(ACCEPTANCE, JSON.pretty_generate(acceptance))

  puts JSON.pretty_generate(verification)
  puts "written #{verify_out}"
  puts "updated #{ACCEPTANCE}"

  exit(pass ? 0 : 1)
end
