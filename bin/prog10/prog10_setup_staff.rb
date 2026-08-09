#!/usr/bin/env ruby
# frozen_string_literal: true

# UK → open_as_manager → создать GM + barista на Prog10 точках (curl, без коммита паролей в git).
require "json"
require "open3"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
JAR = "/tmp/prog10-staff.cookies"
PASSWORD = "demo123456"

SETUP = [
  { tenant_id: "1c064640-4301-4435-8ded-c92fb075e9cc", slug: "alpha-p1",
    staff: [
      { email: "prog10-gm-a1@prog10.local", name: "Prog10 GM A1", roles: %w[general_manager] },
      { email: "prog10-bar-a1@prog10.local", name: "Prog10 Bar A1", roles: %w[barista] }
    ] },
  { tenant_id: "03a4d457-e16f-4998-b764-69b3de083732", slug: "beta-p1",
    staff: [
      { email: "prog10-gm-b1@prog10.local", name: "Prog10 GM B1", roles: %w[general_manager] },
      { email: "prog10-bar-b1@prog10.local", name: "Prog10 Bar B1", roles: %w[barista] }
    ] }
].freeze

def curl(*args)
  out, status = Open3.capture2("curl", "-s", "-c", JAR, "-b", JAR, *args)
  raise "curl failed" unless status
  out
end

def csrf(html)
  html[/name="csrf-token" content="([^"]+)"/, 1]
end

File.delete(JAR) if File.exist?(JAR)
login_html = curl("#{BASE}/login")
tok = csrf(login_html)
curl("-X", "POST", "#{BASE}/login",
  "--data-urlencode", "authenticity_token=#{tok}",
  "--data-urlencode", "user[email]=uk@demo.coffeeos.local",
  "--data-urlencode", "user[password]=#{PASSWORD}",
  "-o", "/dev/null")

results = []
SETUP.each do |point|
  point_results = { tenant_id: point[:tenant_id], slug: point[:slug], staff: [] }
  dash = curl("#{BASE}/admin")
  tok = csrf(dash)
  curl("-X", "POST", "#{BASE}/admin/tenants/#{point[:tenant_id]}/open_as_manager",
    "--data-urlencode", "authenticity_token=#{tok}", "-o", "/dev/null")
  point[:staff].each do |s|
    new_html = curl("#{BASE}/manager/staff/new")
    tok2 = csrf(new_html)
    body = [
      ["authenticity_token", tok2],
      ["user[name]", s[:name]],
      ["user[email]", s[:email]],
      ["user[password]", PASSWORD]
    ]
    s[:roles].each { |r| body << ["role_codes[]", r] }
    args = ["-X", "POST", "#{BASE}/manager/staff", "-H", "Content-Type: application/x-www-form-urlencoded"]
    body.each { |k, v| args += ["--data-urlencode", "#{k}=#{v}"] }
    resp = curl(*args)
    ok = resp.include?("Сотрудник создан") || resp.include?("manager/staff")
    point_results[:staff] << { email: s[:email], roles: s[:roles], created: ok }
    sleep 1
  end
  results << point_results
end

out = { at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), password: "(demo123456)", points: results }
path = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10/staff-rbac/prog10_staff_setup.json")
File.write(path, JSON.pretty_generate(out))
puts JSON.pretty_generate(out)
