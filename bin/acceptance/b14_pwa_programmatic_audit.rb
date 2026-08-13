#!/usr/bin/env ruby
# frozen_string_literal: true

# PWA checklist (эквивалент Lighthouse PWA в LH 13+ без категории pwa).
require "json"
require "net/http"
require "uri"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
TENANT_ID = ENV.fetch("B14_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
SHOP_URL = "#{BASE}/shop?tenant_id=#{TENANT_ID}"

def fetch(url)
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    res = http.get(uri.request_uri)
    [res.code.to_i, res.body, res["content-type"]]
  end
end

checks = {}

code, body, = fetch("#{BASE}/shop/manifest.webmanifest?tenant_id=#{TENANT_ID}")
manifest = code == 200 ? JSON.parse(body) : {}
checks[:https] = { pass: BASE.start_with?("https://"), detail: BASE }
checks[:manifest_200] = { pass: code == 200 }
checks[:display_standalone] = { pass: manifest["display"] == "standalone" }
checks[:scope_shop] = { pass: manifest["scope"] == "/shop" }
checks[:theme_color] = { pass: manifest["theme_color"] == "#ff8c42" }
checks[:icons_192_512] = {
  pass: manifest["icons"]&.any? { |i| i["sizes"] == "192x192" } &&
    manifest["icons"]&.any? { |i| i["sizes"] == "512x512" }
}
checks[:start_url_tenant] = { pass: manifest["start_url"].to_s.include?("tenant_id=") }

_, sw, = fetch("#{BASE}/shop/service-worker.js")
checks[:service_worker] = { pass: sw.include?("coffeeos-shop-shell") && sw.include?("install") }

_, html, = fetch(SHOP_URL)
checks[:manifest_link] = { pass: html.include?('rel="manifest"') }
checks[:viewport_meta] = { pass: html.include?("viewport") }
checks[:theme_color_meta] = { pass: html.include?('name="theme-color"') }
checks[:apple_touch_icon] = { pass: html.include?("apple-touch-icon") }
checks[:apple_mobile_capable] = { pass: html.include?("apple-mobile-web-app-capable") }

%w[/pwa/icon-192.png /pwa/icon-512.png /pwa/apple-touch-icon.png].each do |path|
  c, = fetch("#{BASE}#{path}")
  checks[path] = { pass: c == 200, http: c }
end

all_pass = checks.values.all? { |v| v[:pass] }
result = {
  task: "B14_pwa_programmatic_audit",
  run_at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  note: "LH 13+ убрал категорию pwa; эквивалентный чек-лист",
  score_percent: all_pass ? 100 : (checks.count { |_, v| v[:pass] } * 100 / checks.size),
  pass: all_pass,
  checks: checks
}

out = File.expand_path("../../tmp/b14_pwa_programmatic_audit.json", __dir__)
File.write(out, JSON.pretty_generate(result))
html = <<~HTML
  <!DOCTYPE html><html><head><meta charset="utf-8"><title>B1.4 PWA Audit</title>
  <style>body{font-family:system-ui;background:#1a1a1a;color:#fff;padding:2rem} .ok{color:#4caf50} .bad{color:#f44336}</style></head><body>
  <h1>B1.4 PWA programmatic audit</h1>
  <p>Score: <strong>#{result[:score_percent]}%</strong> — #{all_pass ? "PASS" : "FAIL"}</p>
  <ul>#{checks.map { |k, v| "<li class=\"#{v[:pass] ? "ok" : "bad"}\">#{k}: #{v[:pass] ? "PASS" : "FAIL"}</li>" }.join}</ul>
  </body></html>
HTML
File.write(File.expand_path("../../tmp/b14_pwa_audit_report.html", __dir__), html)
puts JSON.pretty_generate(result)
exit(all_pass ? 0 : 1)
