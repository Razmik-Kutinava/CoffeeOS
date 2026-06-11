#!/usr/bin/env ruby
# frozen_string_literal: true

# Fly smoke: B1.4 PWA manifest + service worker + shop shell.
#
#   ruby bin/b14_pwa_fly_smoke.rb
#   FLY_BIN=flyctl ruby bin/b14_pwa_fly_smoke.rb

require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
TENANT_ID = ENV.fetch("B14_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
OUT = ENV.fetch(
  "OUT",
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_acceptance_#{Time.now.utc.strftime('%Y-%m-%d')}.json"
)

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(4).join(' ')}" unless status.success?

  out
end

result = {
  task: "B14_pwa_fly_smoke",
  run_at: Time.now.utc.iso8601,
  base: BASE,
  tenant_id: TENANT_ID,
  checks: {},
  status: "PASS"
}

begin
  manifest_raw = curl("#{BASE}/shop/manifest.webmanifest?tenant_id=#{TENANT_ID}")
  manifest = JSON.parse(manifest_raw)
  result[:checks][:manifest_json] = {
    pass: manifest["display"] == "standalone" && manifest["scope"] == "/shop",
    name: manifest["name"],
    icons: manifest["icons"]&.size
  }

  sw = curl("#{BASE}/shop/service-worker.js")
  result[:checks][:service_worker] = {
    pass: sw.include?("coffeeos-shop-shell"),
    bytes: sw.bytesize
  }

  shop_html = curl("#{BASE}/shop?tenant_id=#{TENANT_ID}")
  result[:checks][:shop_shell] = {
    pass: shop_html.include?('rel="manifest"') && shop_html.include?("apple-touch-icon"),
    has_tenant_meta: shop_html.include?("shop-tenant-id")
  }

  %w[/pwa/icon-192.png /pwa/icon-512.png /pwa/apple-touch-icon.png].each do |path|
    code_str = curl("-o", File::NULL, "-w", "%{http_code}", "#{BASE}#{path}").strip
    result[:checks][path] = { pass: code_str == "200", http: code_str }
  end

  result[:status] = result[:checks].values.all? { |c| c[:pass] } ? "PASS" : "FAIL"
rescue StandardError => e
  result[:status] = "FAIL"
  result[:error] = e.message
end

File.write(OUT, JSON.pretty_generate(result))
puts JSON.pretty_generate(result)
exit(result[:status] == "PASS" ? 0 : 1)
