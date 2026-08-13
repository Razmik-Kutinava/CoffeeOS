#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

root = File.expand_path("../..", __dir__)
out = File.join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_acceptance_2026-06-12.json")

def read_json(path)
  return nil unless File.file?(path)

  JSON.parse(File.read(path))
end

smoke = read_json(Dir[File.join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_fly_smoke_*.json")].max)
programmatic = read_json(File.join(root, "tmp/b14_pwa_programmatic_audit.json"))
lcp = read_json(File.join(root, "tmp/b14_lcp.json"))

screenshots_dir = "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b14_pwa_2026-06-11"
required_shots = %w[
  lighthouse_pwa_audit.png
  install_prompt_android.png
  standalone_home_screen.png
  offline_catalog.png
  offline_checkout_queued.png
]
shots_present = required_shots.select do |f|
  File.file?(File.join(root, screenshots_dir, f))
end

merged = {
  task: "B14_pwa_formal_acceptance",
  run_at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: smoke&.dig("base") || "https://coffeeos.fly.dev",
  tenant_id: smoke&.dig("tenant_id"),
  fly_smoke: smoke,
  lighthouse_pwa: {
    score_percent: programmatic&.dig("score_percent"),
    pass: programmatic&.dig("pass") == true,
    method: "programmatic_audit",
    note: programmatic&.dig("note"),
    checks: programmatic&.dig("checks")
  },
  lcp_ms_repeat_visit: lcp&.dig("lcp_ms_repeat_visit"),
  lcp_pass: lcp&.dig("lcp_pass") == true,
  lcp_measured_at: lcp&.dig("measured_at"),
  screenshots: shots_present.to_h { |f| [ File.basename(f, ".png"), f ] },
  screenshots_dir: screenshots_dir,
  notes: [
    "lighthouse_pwa: programmatic_audit (LH 13+ без категории pwa)",
    "lcp: repeat visit mobile 4G throttling, Playwright",
    "ios_add_to_home: физическое устройство — после апрува заказчика"
  ],
  customer_signoff: { pass: false, note: "после апрува заказчика" }
}

merged[:status] =
  smoke&.dig("status") == "PASS" &&
  merged[:lighthouse_pwa][:pass] &&
  merged[:lcp_pass] &&
  shots_present.size >= 5 ? "OPS_PASS" : "PARTIAL"

File.write(out, JSON.pretty_generate(merged))
puts JSON.pretty_generate(merged)
exit(merged[:status] == "OPS_PASS" ? 0 : 1)
