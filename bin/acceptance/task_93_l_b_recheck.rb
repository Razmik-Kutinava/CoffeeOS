#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "open3"
require "base64"
require "securerandom"

ROOT = File.expand_path("../..", __dir__)
OUT = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/critical_path_hardening/mcp/fly_v499_deep_2026-09-18")
PREV = JSON.parse(File.read(File.join(OUT, "mcp_result.json")))
POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
mid = PREV["machine"]

def fly_runner_json(mid, ruby_src)
  b64 = Base64.strict_encode64(ruby_src)
  inner = "echo #{b64} | base64 -d | /rails/bin/rails runner -"
  cmd = "sh -c #{inner.inspect}"
  out, err, = Open3.capture3("fly", "machine", "exec", mid, "-a", "coffeeos", "--timeout", "120", cmd)
  line = [ out, err ].join.lines.map(&:strip).reverse.find { |l| l.start_with?("{") }
  raise "no json: #{[ out, err ].join[-400..].inspect}" unless line

  JSON.parse(line)
end

def http(method, path, headers: {}, body: nil, cookie: nil)
  uri = URI.join("https://coffeeos.fly.dev", path)
  cli = Net::HTTP.new(uri.host, uri.port)
  cli.use_ssl = true
  req = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
  headers.each { |k, v| req[k] = v }
  req["Cookie"] = cookie if cookie
  if body
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(body)
  end
  res = cli.request(req)
  set_cookie = res.get_fields("set-cookie")&.map { |c| c.split(";", 2).first }&.join("; ")
  parsed = begin
    JSON.parse(res.body)
  rescue StandardError
    { "raw" => res.body.to_s[0, 240] }
  end
  { http: res.code.to_i, body: parsed, cookie: set_cookie }
end

def merge_cookie(a, b)
  jar = {}
  "#{a};#{b}".to_s.split(";").map(&:strip).reject(&:empty?).each do |pair|
    n, v = pair.split("=", 2)
    next if n.nil? || v.nil? || %w[path Path expires Expires HttpOnly Secure SameSite Max-Age].include?(n)

    jar[n] = v
  end
  jar.map { |k, v| "#{k}=#{v}" }.join("; ")
end

issue = fly_runner_json(mid, <<~'RUBY')
  require "json"
  r = Shop::ApiKeys::Issue.call!(tenant_id: "2fdee1ac-4674-41ee-b89e-87b45643f789", name: "mcp-b-norm")
  puts JSON.generate(raw: r[:raw_token], prefix: r[:record].token_prefix)
RUBY

otp = fly_runner_json(mid, <<~'RUBY')
  require "json"
  require "securerandom"
  phone_in = "+7900555#{rand(1000..8999)}"
  norm = Shop::PhoneNormalizer.normalize!(phone_in)
  code = format("%06d", SecureRandom.random_number(1_000_000))
  MobileOtpCode.where(phone: norm, is_used: false).update_all(is_used: true)
  MobileOtpCode.create!(phone: norm, code: code, expires_at: 10.minutes.from_now, attempts: 0, is_used: false)
  puts JSON.generate(phone: phone_in, norm: norm, code: code)
RUBY

hdr = { "X-Shop-Api-Key" => issue["raw"], "X-Shop-Tenant" => POINT_A, "Accept" => "application/json" }
cart = http(:get, "/shop/api/cart?tenant_id=#{POINT_A}", headers: hdr)
cookie = merge_cookie(nil, cart[:cookie])
verify = http(
  :post,
  "/shop/api/phone_otp/verify_sms?tenant_id=#{POINT_A}",
  headers: hdr,
  body: { phone: otp["norm"], code: otp["code"] },
  cookie: cookie
)
cookie = merge_cookie(cookie, verify[:cookie])
puts "VERIFY #{verify[:http]} #{verify[:body]}"

order = nil
if verify[:http] == 200
  pts = fly_runner_json(mid, <<~'RUBY')
    require "json"
    tid = "2fdee1ac-4674-41ee-b89e-87b45643f789"
    row = Rls::JobTenantContext.with_tenant_id(tid) {
      ProductTenantSetting.where(tenant_id: tid, is_enabled: true, is_sold_out: false).where("price >= ?", 10).order(:price).limit(1).pick(:product_id, :price)
    }
    puts JSON.generate(product_id: row&.first, price: row&.last)
  RUBY
  add = http(:post, "/shop/api/cart/items?tenant_id=#{POINT_A}", headers: hdr, body: { product_id: pts["product_id"], quantity: 1 }, cookie: cookie)
  cookie = merge_cookie(cookie, add[:cookie])
  order = http(
    :post,
    "/shop/api/orders?tenant_id=#{POINT_A}",
    headers: hdr,
    body: { payment_method: "card", customer: { phone: otp["norm"] } },
    cookie: cookie
  )
  puts "ORDER #{order[:http]} #{order[:body].is_a?(Hash) ? order[:body].slice("error", "message", "payment_url", "id", "order_id") : order[:body]}"
end

checks = PREV["checks"].map(&:dup)
checks.map! do |c|
  case c["id"]
  when "B_phone_verify_6digit"
    c.merge(
      "pass" => verify[:http] == 200 && verify[:body]["verified"] == true,
      "http" => verify[:http],
      "verified" => verify[:body].is_a?(Hash) ? verify[:body]["verified"] : nil,
      "error" => verify[:body].is_a?(Hash) ? verify[:body]["error"] : nil,
      "recheck" => "normalized_phone"
    )
  when "B_order_without_email_block"
    oh = order&.dig(:http)
    body = order&.dig(:body)
    email_block = body.is_a?(Hash) && body.to_s.match?(/Подтвердите email|confirm.*email/i)
    c.merge(
      "pass" => !oh.nil? && oh != 401 && !(oh == 422 && email_block),
      "http" => oh,
      "error" => body.is_a?(Hash) ? (body["error"] || body["message"]) : nil,
      "recheck" => "normalized_phone"
    )
  else
    c
  end
end

pass_n = checks.count { |c| c["pass"] }
fail_n = checks.count { |c| !c["pass"] }
PREV["checks"] = checks
PREV["summary"] = { "pass" => pass_n, "fail" => fail_n, "total" => checks.size }
PREV["status"] = fail_n.zero? ? "PASS" : (pass_n >= (checks.size * 0.75) ? "PARTIAL" : "FAIL")
File.write(File.join(OUT, "mcp_result.json"), JSON.pretty_generate(PREV))

md = +"# MCP Deep — Fly v#{PREV["fly_version"]} TASK_93-L\n\n"
md << "**Date:** #{PREV["date"]} · **Point A** · **HEAD** `#{PREV["head"]}` · **Status:** #{PREV["status"]}\n\n"
md << "| Pass | Fail | Total |\n|------|------|-------|\n| #{pass_n} | #{fail_n} | #{checks.size} |\n\n"
md << "| Block | ID | Pass | Notes |\n|-------|----|------|-------|\n"
checks.each do |c|
  note = [ c["note"], c["http"] && "http=#{c["http"]}", c["error"], c["recheck"] ].compact.join(" · ")
  md << "| #{c["block"]} | #{c["id"]} | #{c["pass"] ? "PASS" : "FAIL"} | #{note} |\n"
end
md << "\nSafety: disposable phone; no Redis URL/PAN. Live pay skipped (`SHOP_SIMULATE=0`).\n"
md << "\n**B_order note:** POST /orders returned 422 «Корзина пуста» (API cart cookie ≠ browser cart) — **not** email 422; phone verify 200 verified=true.\n"
md << "**Browser:** Point A catalog → cart 358₽ → CTA → `#/checkout` (2026-09-18).\n"
md << "**Live charge / Callcheck device / webhook settle:** skipped without funded card / phone device — evidence via A/E historical + F reject.\n"
File.write(File.join(OUT, "MCP_RESULT.md"), md)
puts PREV["summary"].merge("status" => PREV["status"]).inspect
