#!/usr/bin/env ruby
# frozen_string_literal: true

# После деплоя CR-05: POST /kiosk/api/auth на 9 точках Prog10.
# Usage:
#   ruby bin/prog10_collect_kiosk_tokens.rb /tmp/prog10_kiosk_tokens.json
#   KIOSK_TOKENS_FILE=/tmp/prog10_kiosk_tokens.json ruby bin/prog10_kiosk_auth_fly_verify.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/kiosk/prog10_kiosk_auth_fly_cr05.json")

POINTS = {
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

tokens_path = ENV["KIOSK_TOKENS_FILE"].to_s
raise "set KIOSK_TOKENS_FILE" if tokens_path.empty? || !File.exist?(tokens_path)

tokens = JSON.parse(File.read(tokens_path))
results = []

tokens.each do |tid, token|
  slug = POINTS[tid] || tid[0, 8]
  row = { slug: slug, tenant_id: tid, token_prefix: token.to_s[0, 8] }
  if token.to_s.empty?
    row[:pass] = false
    row[:error] = "missing token"
    results << row
    next
  end

  begin
    raw = Open3.capture2(
      "curl", "-sS", "-w", "\n%{http_code}",
      "-X", "POST", "#{BASE}/kiosk/api/auth",
      "-H", "X-Device-Token: #{token}"
    ).first
    parts = raw.split("\n")
    code = parts.pop
    body = parts.join("\n")
    parsed = JSON.parse(body)
    row[:http] = code
    row[:tenant_id_ok] = parsed["tenant_id"] == tid
    row[:has_settings] = parsed["kiosk_settings"].is_a?(Hash)
    row[:pass] = code == "200" && row[:tenant_id_ok] && row[:has_settings]
    row[:error] = parsed["error"] if parsed["error"]
  rescue JSON::ParserError => e
    row[:pass] = false
    row[:error] = "json: #{e.message}"
  rescue StandardError => e
    row[:pass] = false
    row[:error] = e.message
  end
  results << row
  sleep 1
end

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  note: "CR-05 fly verify: kiosk/api/auth ×9 after deploy",
  deploy_ref: ENV["DEPLOY_GIT_SHA"],
  results: results
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)
exit(results.all? { |r| r[:pass] } ? 0 : 1)
