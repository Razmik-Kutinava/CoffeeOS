#!/usr/bin/env ruby
# frozen_string_literal: true

# Блок 7 (прогон 10): staff/RBAC изоляция по 9 точкам.
# Проверяет:
# 1) UK -> open_as_manager -> create barista staff на каждой точке
# 2) login barista на своей точке
# 3) own order JSON доступен, foreign order JSON недоступен (404)
#
# Usage:
#   ruby bin/prog10_staff_rbac_isolation.rb
#   OUT=docs/operations/milestones/veha_2/artifacts/prog10_staff_isolation.json ruby bin/prog10_staff_rbac_isolation.rb

require "json"
require "open3"
require "securerandom"

BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
PASSWORD = ENV.fetch("STAFF_PASSWORD", "demo123456")
OUT = ENV.fetch("OUT", "docs/operations/milestones/veha_2/artifacts/prog10_staff_isolation.json")

POINTS = [
  { slug: "demo-a", tenant_id: "2fdee1ac-4674-41ee-b89e-87b45643f789", barista_expected: true },
  { slug: "demo-b", tenant_id: "655aaccb-004a-4bb9-a50a-ce618854dda3", barista_expected: true },
  { slug: "demo-prep", tenant_id: "d47165db-81c9-4e9d-bc50-e37fe610d86c", barista_expected: false },
  { slug: "alpha-p1", tenant_id: "1c064640-4301-4435-8ded-c92fb075e9cc", barista_expected: true },
  { slug: "alpha-p2", tenant_id: "edf8a0a9-38e7-4049-b9c6-3e08c6c23a76", barista_expected: true },
  { slug: "alpha-p3", tenant_id: "d29fcf3a-da72-4a95-9683-9cfa71a2d865", barista_expected: true },
  { slug: "beta-p1", tenant_id: "03a4d457-e16f-4998-b764-69b3de083732", barista_expected: true },
  { slug: "beta-p2", tenant_id: "628a937b-f4e2-43b7-bd7f-9fa44f031460", barista_expected: true },
  { slug: "beta-p3", tenant_id: "b57c2a88-91a5-481e-b44f-29e29c77cfb5", barista_expected: true }
].freeze

def run_curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.join(' ')}" unless status.success?

  out
end

def csrf_token(html)
  html[/name="csrf-token" content="([^"]+)"/, 1]
end

def login_user!(email:, password:, jar:)
  File.delete(jar) if File.exist?(jar)
  login_html = run_curl("-c", jar, "#{BASE}/login")
  token = csrf_token(login_html)
  raise "no csrf on login page for #{email}" if token.nil? || token.empty?

  body = run_curl(
    "-b", jar, "-c", jar,
    "-X", "POST", "#{BASE}/login",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[email]=#{email}",
    "--data-urlencode", "user[password]=#{password}",
    "-D", "-", "-o", "-"
  )
  raise "login failed for #{email}" unless body.include?("HTTP/2 302") || body.include?("HTTP/1.1 302")
end

def open_as_manager!(uk_jar:, tenant_id:)
  admin_html = run_curl("-b", uk_jar, "-c", uk_jar, "#{BASE}/admin")
  token = csrf_token(admin_html)
  raise "no admin csrf" if token.nil? || token.empty?

  run_curl(
    "-b", uk_jar, "-c", uk_jar,
    "-X", "POST", "#{BASE}/admin/tenants/#{tenant_id}/open_as_manager",
    "--data-urlencode", "authenticity_token=#{token}",
    "-o", "/dev/null"
  )
end

def create_staff!(uk_jar:, name:, email:, role_code:)
  form_html = run_curl("-b", uk_jar, "-c", uk_jar, "#{BASE}/manager/staff/new")
  token = csrf_token(form_html)
  raise "no staff csrf for #{email}" if token.nil? || token.empty?

  response = run_curl(
    "-b", uk_jar, "-c", uk_jar,
    "-X", "POST", "#{BASE}/manager/staff",
    "-H", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "authenticity_token=#{token}",
    "--data-urlencode", "user[name]=#{name}",
    "--data-urlencode", "user[email]=#{email}",
    "--data-urlencode", "user[password]=#{PASSWORD}",
    "--data-urlencode", "role_codes[]=#{role_code}"
  )

  created = response.include?("Сотрудник создан")
  { created: created }
end

def shop_key_for(tenant_id)
  html = run_curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key for #{tenant_id}" if key.nil? || key.empty?

  key
end

def create_order_for_tenant!(tenant_id:, key:, label:)
  jar = "/tmp/prog10-iso-cart-#{tenant_id[0, 8]}.cookies"
  File.delete(jar) if File.exist?(jar)
  run_curl("-c", jar, "#{BASE}/shop?tenant_id=#{tenant_id}", "-o", "/dev/null")

  products = JSON.parse(
    run_curl("#{BASE}/shop/api/products", "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}")
  )
  product_id = products.dig("data", 0, "id")
  raise "no products for #{tenant_id}" if product_id.nil?

  run_curl(
    "-X", "POST", "#{BASE}/shop/api/cart/add", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { product_id: product_id, quantity: 1, selected_modifiers: [] }.to_json
  )

  phone = format("+7905%07d", rand(10_000_000))
  body = run_curl(
    "-X", "POST", "#{BASE}/shop/api/orders", "-c", jar, "-b", jar,
    "-H", "X-Shop-Tenant: #{tenant_id}", "-H", "X-Shop-Api-Key: #{key}",
    "-H", "Content-Type: application/json",
    "--data-binary", { name: label, phone: phone, payment_method: "cash" }.to_json
  )
  parsed = JSON.parse(body)
  oid = parsed["order_id"]
  raise "order create failed for #{tenant_id}: #{body}" if oid.nil?

  oid
end

def code_for(path, jar:)
  run_curl("-b", jar, "-o", "/dev/null", "-w", "%{http_code}", "#{BASE}#{path}").strip
end

timestamp_suffix = Time.now.utc.strftime("%m%d%H%M")
uk_jar = "/tmp/prog10-iso-uk.cookies"
login_user!(email: "uk@demo.coffeeos.local", password: PASSWORD, jar: uk_jar)

shop_key = shop_key_for(POINTS.first[:tenant_id])
orders_by_tenant = {}

POINTS.each do |point|
  orders_by_tenant[point[:tenant_id]] = create_order_for_tenant!(
    tenant_id: point[:tenant_id],
    key: shop_key,
    label: "ISO-#{point[:slug]}"
  )
end

results = []
POINTS.each_with_index do |point, idx|
  foreign_point = POINTS[(idx + 1) % POINTS.length]
  open_as_manager!(uk_jar: uk_jar, tenant_id: point[:tenant_id])

  email = "iso-bar-#{point[:slug]}-#{timestamp_suffix}@prog10.local"
  create_res = create_staff!(
    uk_jar: uk_jar,
    name: "ISO Barista #{point[:slug]}",
    email: email,
    role_code: "barista"
  )

  staff_jar = "/tmp/prog10-iso-#{point[:slug]}.cookies"
  login_user!(email: email, password: PASSWORD, jar: staff_jar)

  barista_code = code_for("/barista", jar: staff_jar)
  own_code = code_for("/barista/orders/#{orders_by_tenant[point[:tenant_id]]}.json", jar: staff_jar)
  foreign_code = code_for("/barista/orders/#{orders_by_tenant[foreign_point[:tenant_id]]}.json", jar: staff_jar)

  pass =
    if point[:barista_expected]
      barista_code == "200" && own_code == "200" && foreign_code == "404"
    else
      # Для production kitchen barista-панель закрыта по модулю/роли.
      barista_code == "302" && own_code == "302" && foreign_code == "302"
    end

  results << {
    tenant_id: point[:tenant_id],
    slug: point[:slug],
    barista_expected: point[:barista_expected],
    barista_email: email,
    staff_created: create_res[:created],
    barista_http: barista_code,
    own_order_http: own_code,
    foreign_order_http: foreign_code,
    pass: pass
  }
end

report = {
  at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  base: BASE,
  note: "staff/rbac isolation for 9 points; own order visible, foreign order hidden",
  results: results
}

File.write(OUT, JSON.pretty_generate(report))
puts JSON.pretty_generate(report)

exit(results.all? { |r| r[:pass] } ? 0 : 1)
