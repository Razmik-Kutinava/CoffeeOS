#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.4 formal acceptance on Fly: smoke + Lighthouse + LCP + screenshots.
#
#   ruby bin/b14_pwa_acceptance_fly.rb

require "json"
require "open3"

root = File.expand_path("..", __dir__)
smoke_path = File.join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_fly_smoke_#{Time.now.utc.strftime('%Y-%m-%d')}.json")
ENV["OUT"] = smoke_path
smoke_ok = system("ruby", File.join(root, "bin/b14_pwa_fly_smoke.rb"))

out = File.join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_acceptance_2026-06-12.json")
existing = File.file?(out) ? JSON.parse(File.read(out)) : {}
existing[:fly_smoke] = File.file?(smoke_path) ? JSON.parse(File.read(smoke_path)) : nil
File.write(out, JSON.pretty_generate(existing))

screenshots_ok = system("node", File.join(root, "bin/b14_pwa_acceptance_fly.mjs"), "--screenshots-only")
lighthouse_ok = system("node", File.join(root, "bin/b14_pwa_acceptance_fly.mjs"), "--lighthouse-only")

merged = File.file?(out) ? JSON.parse(File.read(out)) : {}
merged[:smoke_ok] = smoke_ok
merged[:screenshots_ok] = screenshots_ok
merged[:lighthouse_ok] = lighthouse_ok
merged[:run_at] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
File.write(out, JSON.pretty_generate(merged))
puts JSON.pretty_generate(merged)
exit(merged["status"] == "OPS_PASS" ? 0 : 1)
