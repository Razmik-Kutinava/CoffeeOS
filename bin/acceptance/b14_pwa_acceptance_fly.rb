#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.4 полный прогон приёмки на Fly:
#   smoke → programmatic_audit → browser_shots → finalize
#
#   ruby bin/acceptance/b14_pwa_acceptance_fly.rb

root = File.expand_path("../..", __dir__)
steps = [
  [ "fly smoke", %w[ruby bin/acceptance/b14_pwa_fly_smoke.rb] ],
  [ "programmatic audit", %w[ruby bin/acceptance/b14_pwa_programmatic_audit.rb] ],
  [ "browser shots + LCP", %w[node bin/acceptance/b14_pwa_browser_shots.mjs] ],
  [ "finalize", %w[ruby bin/acceptance/b14_finalize_acceptance.rb] ]
]

steps.each do |label, cmd|
  puts "=== #{label} ==="
  ok = system(*cmd, chdir: root)
  unless ok
    warn "FAILED: #{label}"
    exit 1
  end
end

out = File.join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_acceptance_2026-06-12.json")
puts File.read(out) if File.file?(out)
exit 0
