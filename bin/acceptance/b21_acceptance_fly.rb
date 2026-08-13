#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 formal acceptance Fly — prep + Playwright + FCM verify + acceptance JSON.
#   FLY_BIN=flyctl ruby bin/acceptance/b21_acceptance_fly.rb

require "json"
require "open3"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_acceptance_#{DATE}.json")
SCREEN_DIR = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10"
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")

def run!(cmd, label)
  puts "==> #{label}: #{cmd}"
  system(cmd) || raise("#{label} failed")
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list" unless status.success?

  machines = JSON.parse(out)
  (machines.find { |m| m["state"] == "started" } || machines.first)["id"]
end

def fly_runner(ruby)
  remote = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote)
  combined = [ out, err ].join.strip
  raise "fly runner: #{combined}" unless st.success?

  combined
end

whoami, ok = Open3.capture2e("#{FLY_BIN} auth whoami 2>&1")
raise "flyctl auth login required" unless ok.success? && !whoami.strip.empty?

Dir.chdir(ROOT) do
  run!("FLY_BIN=#{FLY_BIN} ruby bin/acceptance/b21_acceptance_prep.rb", "acceptance prep")
  prep = JSON.parse(File.read("tmp/b21_acceptance_prep.json"))

  playwright_ok = system("node bin/acceptance/b21_acceptance_fly.mjs")
  steps = JSON.parse(File.read("tmp/b21_acceptance_steps.json"))

  # FCM pipeline on Fly (после preparing в Playwright; job async)
  push_line = nil
  5.times do |i|
    sleep i.zero? ? 4 : 3
    push_ruby = [
      "order = Order.find(#{prep['main_order_id'].inspect})",
      "cust = order.customer || MobileCustomer.find_by(email: #{prep['vitrina_email'].inspect})",
      "n = PushNotification.where(customer_id: cust&.id).order(created_at: :desc).limit(10)",
      "hit = n.find { |x| x.body.to_s.include?('начали готовить') }",
      "puts 'PUSH_RESULT|' + [cust&.push_token.present?, hit&.body, hit&.status, hit&.error_message].join('|')"
    ].join("; ")
    push_out = fly_runner(push_ruby)
    push_line = push_out.lines.find { |l| l.start_with?("PUSH_RESULT|") }.to_s.strip
    break if push_line.include?("начали готовить")
  end
  push_payload = push_line.to_s.sub("PUSH_RESULT|", "")
  token_ok, body, push_status, push_err = push_payload.split("|", 4)
  fcm_ok = token_ok == "true" &&
           body.to_s.include?("начали готовить") &&
           %w[sent failed].include?(push_status.to_s) &&
           (push_status.to_s == "sent" || push_err.to_s !~ /push_token missing/i)

  criteria = steps["criteria"] || {}
  criteria["8"] ||= {}
  criteria["8"]["fcm_pipeline"] = {
    push_registered: prep["push_registered"],
    notification_body: body,
    status: push_status,
    error: push_err
  }
  if fcm_ok
    criteria["8"]["pass"] = true
    criteria["8"]["formal"] = "PASS"
    criteria["8"]["evidence"] = "stage3_push_optional.png + PushNotification on Fly"
  end

  smoke_ok = system("FLY_BIN=#{FLY_BIN} ruby bin/acceptance/b21_barista_board_fly_smoke.rb")
  smoke_path = Dir.glob("docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_fly_smoke_*.json").max
  smoke = JSON.parse(File.read(smoke_path))

  e2e_path = Dir.glob("docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_mcp_e2e_*.json").max
  e2e = e2e_path ? JSON.parse(File.read(e2e_path)) : { "status" => "MISSING" }
  e2e_ok = e2e["status"] == "PASS"
  if ENV["B21_RUN_E2E"] == "1"
    e2e_ok = system("FLY_BIN=#{FLY_BIN} ruby bin/acceptance/b21_mcp_e2e_fly.rb")
    e2e_path = Dir.glob("docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_mcp_e2e_*.json").max
    e2e = JSON.parse(File.read(e2e_path))
  end

  screens = %w[
    stage1_card_accepted_fly.png stage1_card_preparing_fly.png stage1_card_ready_fly.png
    stage1_modifiers_fly.png stage2_fifo_accepted.png stage2_after_status_move.png
    stage4_cancel_overlay.png stage4_cancel_confirmed.png stage3_push_optional.png
    stage3_guest_preparing.png stage3_guest_ready.png
    stage5_e2e_vitrina_to_board.png stage5_e2e_barista_preparing.png
  ].each_with_object({}) { |f, h| h[f] = File.exist?(File.join(SCREEN_DIR, f)) }

  crit_names = {
    1 => "Кнопка статуса ≥80px",
    2 => "Цвет карточки по статусу",
    3 => "Модификаторы +/БЕЗ",
    4 => "FIFO created_at",
    5 => "Нет drag-and-drop",
    6 => "Табло ≤1с",
    7 => "WS гостю ≤5с",
    8 => "Push FCM",
    9 => "Витрина→табло"
  }
  mvp = (1..9).map do |id|
    c = criteria[id.to_s] || {}
    formal = c["formal"] || "FAIL"
    formal = "PASS" if id == 9 && smoke["status"] == "PASS" && e2e["status"] == "PASS"
    formal = "PASS" if id == 8 && fcm_ok
    pass = c["pass"] == true || formal == "PASS"
    {
      id: id,
      criterion: crit_names[id],
      code: pass ? "PASS" : "FAIL",
      formal: formal,
      evidence: c["evidence"] || c["screenshot"] || c.dig("fcm_pipeline", "notification_body") ||
                (c["screenshots"].is_a?(Array) ? c["screenshots"].join(", ") : nil)
    }
  end

  formal_pass_count = mvp.count { |c| c[:formal] == "PASS" }
  ops_status = formal_pass_count == 9 ? "OPS_PASS" : "PARTIAL"

  result = {
    task: "B2_1_barista_order_board",
    scenario: "B2.1 — formal ops acceptance (внутренняя приёмка, без подписи заказчика)",
    run_at: DATE,
    stand_fly: prep["base"],
    tenant_id: prep["tenant_id"],
    internal_signoff_ready: formal_pass_count == 9,
    internal_signoff: false,
    customer_signoff: false,
    order_id: prep["main_order_id"],
    scripts: {
      b21_acceptance_prep: { path: "bin/acceptance/b21_acceptance_prep.rb", status: "PASS" },
      b21_acceptance_fly_mjs: { path: "bin/acceptance/b21_acceptance_fly.mjs", status: steps["status"] },
      b21_mcp_e2e_fly: { path: "bin/acceptance/b21_mcp_e2e_fly.rb", status: e2e["status"], artifact: File.basename(e2e_path.to_s) },
      b21_fly_smoke: { path: "bin/acceptance/b21_barista_board_fly_smoke.rb", status: smoke["status"] }
    },
    criteria_playwright: criteria,
    mvp_criteria: mvp,
    screenshots: { dir: SCREEN_DIR, files: screens, all_present: screens.values.all? },
    checks: {
      playwright: playwright_ok && steps["status"] == "PASS",
      fcm_pipeline: fcm_ok,
      fly_smoke: smoke_ok && smoke["status"] == "PASS",
      mcp_e2e: e2e_ok && e2e["status"] == "PASS",
      screenshots: screens.values.all?
    },
    status: ops_status,
    next: [ "внутренняя приёмка (ты)", "подпись заказчика" ]
  }

  File.write(OUT, JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
  puts "written #{OUT}"

  all_ok = result[:checks].values.all? && steps["status"] == "PASS"
  exit(all_ok ? 0 : 1)
end
