#!/usr/bin/env ruby
# frozen_string_literal: true

# Patch pass for TASK_93-L deep MCP fails (B/D key + H constant).
require "json"
require "net/http"
require "uri"
require "open3"
require "base64"
require "securerandom"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
FLY_APP = "coffeeos"
FLY_BIN = "fly"
BASE = "https://coffeeos.fly.dev"
POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
OUT = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/critical_path_hardening/mcp/fly_v499_deep_2026-09-18")
PREV = JSON.parse(File.read(File.join(OUT, "mcp_result.json")))

def fly_runner_json(mid, ruby_src)
  b64 = Base64.strict_encode64(ruby_src)
  inner = "echo #{b64} | base64 -d | /rails/bin/rails runner -"
  cmd = "sh -c #{inner.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", mid, "-a", FLY_APP, "--timeout", "120", cmd)
  text = [ out, err ].join
  line = text.lines.map(&:strip).reverse.find { |l| l.start_with?("{") }
  raise "no json: #{text[-500..].inspect}" unless line

  JSON.parse(line)
end

def http(method, path, headers: {}, body: nil, cookie: nil)
  uri = URI.join(BASE, path)
  cli = Net::HTTP.new(uri.host, uri.port)
  cli.use_ssl = true
  cli.open_timeout = 20
  cli.read_timeout = 60
  req = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
  headers.each { |k, v| req[k] = v }
  req["Cookie"] = cookie if cookie
  if body
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(body)
  end
  res = cli.request(req)
  set_cookie = res.get_fields("set-cookie")&.map { |c| c.split(";").first }&.join("; ")
  parsed = begin
    JSON.parse(res.body)
  rescue StandardError
    { "raw" => res.body.to_s[0, 200] }
  end
  { http: res.code.to_i, body: parsed, cookie: set_cookie }
end

def merge_cookie(existing, set_cookie)
  jar = {}
  "#{existing};#{set_cookie}".to_s.split(";").map(&:strip).reject(&:empty?).each do |pair|
    n, v = pair.split("=", 2)
    next if n.nil? || v.nil? || %w[path Path expires Expires HttpOnly Secure SameSite Max-Age].include?(n)

    jar[n] = v
  end
  jar.map { |k, v| "#{k}=#{v}" }.join("; ")
end

mid = PREV["machine"]
checks = PREV["checks"].map(&:dup)

issue = fly_runner_json(
  mid,
  <<~'RUBY'
    require "json"
    tid = "2fdee1ac-4674-41ee-b89e-87b45643f789"
    r = Shop::ApiKeys::Issue.call!(tenant_id: tid, name: "mcp-93l-patch")
    puts JSON.generate(prefix: r[:record].token_prefix, raw: r[:raw_token])
  RUBY
)
key = issue["raw"]
hdr = { "X-Shop-Api-Key" => key, "X-Shop-Tenant" => POINT_A, "Accept" => "application/json" }

h = fly_runner_json(
  mid,
  <<~'RUBY'
    require "json"
    names = []
    names << "CartService" if defined?(Shop::CartService)
    names << "OverflowError" if defined?(Shop::CartService) && Shop::CartService.const_defined?(:OverflowError, false)
    names << "overflow_const" if defined?(Shop::CartService::OverflowError)
    # also search ObjectSpace-ish via constants
    nested = Shop.constants.grep(/Cart|Overflow/i)
    puts JSON.generate(
      cart_defined: defined?(Shop::CartService).present?,
      overflow: defined?(Shop::CartService::OverflowError).present?,
      cart_constants: (defined?(Shop::CartService) ? Shop::CartService.constants.map(&:to_s) : []),
      shop_nested: nested.map(&:to_s)
    )
  RUBY
)

phone = "+7900#{SecureRandom.random_number(10_000_000..99_999_999)}"
otp = fly_runner_json(
  mid,
  <<~RUBY
    require "json"
    require "securerandom"
    phone = #{phone.inspect}
    code = format("%06d", SecureRandom.random_number(1_000_000))
    MobileOtpCode.where(phone: phone, is_used: false).update_all(is_used: true) rescue nil
    MobileOtpCode.create!(phone: phone, code: code, expires_at: 10.minutes.from_now, attempts: 0, is_used: false)
    puts JSON.generate(phone: phone, code: code)
  RUBY
)

cart = http(:get, "/shop/api/cart?tenant_id=#{POINT_A}", headers: hdr)
cookie = merge_cookie(nil, cart[:cookie])
verify = http(
  :post,
  "/shop/api/phone_otp/verify_sms?tenant_id=#{POINT_A}",
  headers: hdr,
  body: { phone: otp["phone"], code: otp["code"] },
  cookie: cookie
)
cookie = merge_cookie(cookie, verify[:cookie])

pts = fly_runner_json(
  mid,
  <<~'RUBY'
    require "json"
    tid = "2fdee1ac-4674-41ee-b89e-87b45643f789"
    row = Rls::JobTenantContext.with_tenant_id(tid) {
      ProductTenantSetting.where(tenant_id: tid, is_enabled: true, is_sold_out: false).where("price >= ?", 10).order(:price).limit(1).pick(:product_id, :price)
    }
    puts JSON.generate(product_id: row&.first, price: row&.last)
  RUBY
)

order = nil
if pts["product_id"] && verify[:http] == 200
  http(:post, "/shop/api/cart/items?tenant_id=#{POINT_A}", headers: hdr, body: { product_id: pts["product_id"], quantity: 1 }, cookie: cookie).tap do |r|
    cookie = merge_cookie(cookie, r[:cookie])
  end
  order = http(
    :post,
    "/shop/api/orders?tenant_id=#{POINT_A}",
    headers: hdr,
    body: { payment_method: "card", customer: { phone: otp["phone"] } },
    cookie: cookie
  )
end

hist = http(:get, "/shop/api/orders/history?tenant_id=#{POINT_A}", headers: hdr, cookie: cookie)

patched = {
  "B_phone_verify_6digit" => {
    "pass" => verify[:http] == 200 && verify[:body].is_a?(Hash) && verify[:body]["verified"] == true,
    "http" => verify[:http],
    "verified" => verify[:body].is_a?(Hash) ? verify[:body]["verified"] : nil,
    "key_prefix" => issue["prefix"]
  },
  "B_order_without_email_block" => begin
    oh = order&.dig(:http)
    body = order&.dig(:body)
    email_block = body.is_a?(Hash) && body.to_s.match?(/Подтвердите email|confirm.*email/i)
    {
      "pass" => !oh.nil? && oh != 401 && !(oh == 422 && email_block),
      "http" => oh,
      "error" => body.is_a?(Hash) ? (body["error"] || body["message"]) : nil,
      "note" => "tenant key issued; expect not email-only 422"
    }
  end,
  "D_history_default_page" => {
    "pass" => hist[:http] == 200,
    "http" => hist[:http],
    "length" => hist[:body].is_a?(Array) ? hist[:body].length : Array(hist[:body].is_a?(Hash) ? (hist[:body]["orders"] || hist[:body]["data"]) : []).length
  },
  "H_overflow_error_defined" => {
    "pass" => h["overflow"] == true || h["cart_constants"].to_a.include?("OverflowError"),
    "cart_constants" => h["cart_constants"],
    "shop_nested" => h["shop_nested"],
    "note" => "const probe"
  }
}

checks.map! do |c|
  if patched.key?(c["id"])
    c.merge(patched[c["id"]]).merge("recheck" => true)
  else
    c
  end
end

pass_n = checks.count { |c| c["pass"] }
fail_n = checks.count { |c| !c["pass"] }
PREV["checks"] = checks
PREV["summary"] = { "pass" => pass_n, "fail" => fail_n, "total" => checks.size }
PREV["status"] = fail_n.zero? ? "PASS" : (pass_n >= (checks.size * 0.75) ? "PARTIAL" : "FAIL")
PREV["patch"] = "tenant_key_issue + H/B/D recheck"
File.write(File.join(OUT, "mcp_result.json"), JSON.pretty_generate(PREV))

md = +"# MCP Deep — Fly v#{PREV["fly_version"]} TASK_93-L\n\n"
md << "**Date:** #{PREV["date"]} · **Point A** · **HEAD** `#{PREV["head"]}` · **Status:** #{PREV["status"]}\n\n"
md << "| Pass | Fail | Total |\n|------|------|-------|\n| #{pass_n} | #{fail_n} | #{checks.size} |\n\n"
md << "| Block | ID | Pass | Notes |\n|-------|----|------|-------|\n"
checks.each do |c|
  note = [ c["note"], c["http"] && "http=#{c["http"]}", c["reason"] ].compact.join(" · ")
  md << "| #{c["block"]} | #{c["id"]} | #{c["pass"] ? "PASS" : "FAIL"} | #{note} |\n"
end
md << "\nSafety: disposable phone; no Redis URL/PAN in artifact. Live pay skipped (`SHOP_SIMULATE=0`).\n"
File.write(File.join(OUT, "MCP_RESULT.md"), md)
puts JSON.pretty_generate(PREV["summary"].merge(status: PREV["status"], patched: patched.transform_values { |v| v["pass"] }))
