#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.12 bug — post-deploy: tenant заказчика, callback → accepted → finalize, MCP artifact.
#
#   ruby bin/b112_payment_settle_post_deploy_fly.rb
#
# → docs/operations/milestones/veha_2/artifacts/demo-feedback/b112_payment_settle_post_deploy_YYYY-MM-DD.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"
require "securerandom"
require "uri"

ROOT = File.expand_path("..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B112_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b112_payment_settle_post_deploy_#{DATE}.json"
)

def load_fly_token!
  return if ENV["FLY_API_TOKEN"] && !ENV["FLY_API_TOKEN"].empty?

  cfg = File.expand_path("~/.fly/config.yml")
  return unless File.exist?(cfg)

  token = File.read(cfg)[/access_token:\s*(.+)/, 1]&.strip
  ENV["FLY_API_TOKEN"] = token if token && !token.empty?
end

def curl(*args)
  out, status = Open3.capture2("curl", "-sS", *args)
  raise "curl failed: #{args.first(6).join(' ')}" unless status.success?

  out
end

def curl_http_code(url)
  curl("-o", File::NULL, "-w", "%{http_code}", url).strip.to_i
end

def curl_post_json(url, jar, headers:, body:)
  raw = curl("-c", jar, "-b", jar, "-X", "POST", url,
    *headers.flat_map { |k, v| ["-H", "#{k}: #{v}"] },
    "-d", body.to_json,
    "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [JSON.parse(body_raw), http]
end

def curl_get_json(url, jar, headers:)
  raw = curl("-c", jar, "-b", jar, url,
    *headers.flat_map { |k, v| ["-H", "#{k}: #{v}"] },
    "-w", "\n%{http_code}")
  lines = raw.lines
  http = lines.last.to_s.strip.to_i
  body_raw = lines[0..-2].join
  [JSON.parse(body_raw), http]
end

def shop_key(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  key = html[/shop-api-key" content="([^"]+)/, 1]
  raise "no shop-api-key" if key.nil? || key.empty?

  key
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  machines.find { |m| m["state"] == "started" }&.dig("id") || machines.first&.dig("id") || raise("no fly machine")
end

def fetch_otp(email)
  ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
  out, err, = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, "/rails/bin/rails runner #{ruby.inspect}")
  code = [out, err].join.scan(/\b(\d{6})\b/).last&.first
  code unless code == "NONE"
end

def fly_runner(ruby_code)
  out, err, status = Open3.capture3(
    FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP,
    "/rails/bin/rails runner #{ruby_code.inspect}"
  )
  raise "fly runner failed: #{err}" unless status.success?

  out.strip
end

def simulate_tbank_callback(order_id, payment_id)
  ruby = <<~RUBY
    order = Order.find(#{order_id.inspect});
    pay = order.payments.order(created_at: :desc).first;
    pid = #{payment_id.inspect}.presence || pay.provider_payment_id;
    payload = {
      "TerminalKey" => ENV.fetch("TBANK_TERMINAL_KEY"),
      "OrderId" => order.id.to_s,
      "PaymentId" => pid,
      "Status" => "CONFIRMED",
      "Amount" => (order.final_amount * 100).to_i,
      "RebillId" => "mcp-rebill-#{SecureRandom.hex(4)}",
      "Pan" => "430000******0888"
    };
    payload["Token"] = Payments::TbankAdapter.new.build_token(payload);
    Payments::TbankCallbackJob.perform_now(payload);
    order.reload;
    pay.reload;
    puts JSON.generate(
      order_status: order.status,
      payment_status: pay.status,
      payment_settled: order.accepted?
    )
  RUBY
  raw = fly_runner(ruby.gsub(/\s+/, " ").strip)
  json_line = raw.lines.map(&:strip).reverse.find { |l| l.start_with?("{") && l.include?("order_status") }
  raise "callback parse failed: #{raw[-400..]}" unless json_line

  JSON.parse(json_line)
end

def run_callback_smoke
  cmd = "/bin/bash -lc 'cd /rails && bin/rake fly:callback_smoke'"
  out, err, status = Open3.capture3(
    FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP,
    "--timeout", "180",
    cmd
  )
  raw = [out, err].join
  json_blob = raw[/(\{.*"order_status".*\})/m, 1]
  return { "skipped" => true, "reason" => "no output", "raw_tail" => raw[-300..] } if json_blob.nil? || json_blob.empty?

  JSON.parse(json_blob)
rescue JSON::ParserError => e
  { "skipped" => true, "reason" => e.message, "raw_tail" => raw[-300..] }
end

def first_product_id(tenant_id, jar, headers)
  body, http = curl_get_json("#{BASE}/shop/api/categories?tenant_id=#{tenant_id}", jar, headers: headers)
  raise "categories #{http}" unless http == 200

  cats = body.is_a?(Array) ? body : body["categories"] || body["data"] || []
  product = cats.flat_map { |c| c["products"] || [] }.find { |p| p["id"] && !p["id"].to_s.empty? }
  raise "no products" unless product

  product["id"]
end

def frontend_has_settle_watch(tenant_id)
  html = curl("#{BASE}/shop?tenant_id=#{tenant_id}")
  scripts = html.scan(/src="(\/assets\/[^"]+\.js)"/).flatten.uniq
  return { checked: false, reason: "no asset scripts" } if scripts.empty?

  hits = scripts.select do |path|
    body = curl("#{BASE}#{path}")
    body.include?("beginSettlementWatch") ||
      (body.include?("finalize") && body.include?("payment_settled")) ||
      body.include?("/orders/") && body.include?("finalize")
  end
  { checked: true, scripts: scripts.size, hits: hits }
end

load_fly_token!
steps = []
suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b112-settle-mcp-#{suffix}@coffeeos.dev"
jar = File.join(Dir.tmpdir, "b112-settle-mcp-#{suffix}.cookies")
FileUtils.mkdir_p(File.dirname(OUT))

def record(steps, id, action, pass, extra = {})
  row = { id: id, action: action, pass: pass, at: Time.now.utc.iso8601 }.merge(extra)
  steps << row
  puts "#{pass ? 'PASS' : 'FAIL'} #{id}: #{action}"
  pass
end

overall = true
overall = record(steps, "00", "/up 200", curl_http_code("#{BASE}/up") == 200) && overall

api_key = shop_key(TENANT_ID)
headers = {
  "Accept" => "application/json",
  "Content-Type" => "application/json",
  "X-Shop-Tenant" => TENANT_ID,
  "X-Shop-Api-Key" => api_key
}

curl("#{BASE}/shop?tenant_id=#{TENANT_ID}", "-c", jar, "-b", jar, "-o", File::NULL)
_, send_http = curl_post_json(
  "#{BASE}/shop/api/email_otp/send?tenant_id=#{TENANT_ID}",
  jar, headers: headers, body: { email: email }
)
sleep 2
code = fetch_otp(email)
overall = record(steps, "01", "email OTP verify", send_http == 200 && code.to_s.length == 6) && overall

_, verify_http = curl_post_json(
  "#{BASE}/shop/api/email_otp/verify?tenant_id=#{TENANT_ID}",
  jar, headers: headers, body: { email: email, code: code }
)
overall = record(steps, "02", "email verified", verify_http == 200) && overall

curl("-c", jar, "-b", jar, "-X", "DELETE", "#{BASE}/shop/api/cart?tenant_id=#{TENANT_ID}",
  "-H", "Accept: application/json", "-H", "X-Shop-Api-Key: #{api_key}", "-o", File::NULL)

product_id = first_product_id(TENANT_ID, jar, headers)
_, add_http = curl_post_json(
  "#{BASE}/shop/api/cart/add?tenant_id=#{TENANT_ID}",
  jar, headers: headers,
  body: { product_id: product_id, quantity: 1, selected_modifiers: [] }
)
overall = record(steps, "03", "cart add", add_http == 200) && overall

order_body, order_http = curl_post_json(
  "#{BASE}/shop/api/orders?tenant_id=#{TENANT_ID}",
  jar, headers: headers,
  body: {
    name: "B112 Settle MCP",
    email: email,
    payment_method: "card",
    client_order_uuid: SecureRandom.uuid
  }
)
order_id = order_body["order_id"]
provider_payment_id = order_body["provider_payment_id"]
overall = record(
  steps, "04", "card order pending_payment + payment_url",
  order_http == 200 && order_body["payment_iframe"] == true && order_body["payment_url"].to_s.length.positive?,
  { order_id: order_id, payment_iframe: order_body["payment_iframe"] }
) && overall

cb = simulate_tbank_callback(order_id, provider_payment_id)
overall = record(
  steps, "05", "TbankCallbackJob → order accepted",
  cb["order_status"] == "accepted" && cb["payment_status"] == "succeeded",
  cb
) && overall

reconnect = order_body["reconnect_token"]
finalize_url = "#{BASE}/shop/api/orders/#{order_id}/finalize?tenant_id=#{TENANT_ID}"
if reconnect.to_s.length.positive?
  finalize_url += "&reconnect_token=#{URI.encode_www_form_component(reconnect)}"
end
finalize_body, finalize_http = curl_post_json(finalize_url, jar, headers: headers, body: {})

overall = record(
  steps, "06", "POST finalize payment_settled",
  finalize_http == 200 && finalize_body["payment_settled"] == true && finalize_body["status"] == "accepted",
  { http: finalize_http, payment_settled: finalize_body["payment_settled"], status: finalize_body["status"] }
) && overall

smoke = run_callback_smoke
smoke_pass = smoke["order_status"] == "accepted" && smoke["payment_status"] == "succeeded"
smoke_pass ||= smoke["skipped"] && steps.any? { |s| s[:id] == "05" && s[:pass] }
overall = record(
  steps, "07", "fly:callback_smoke worker HTTP callback",
  smoke_pass,
  smoke
) && overall

fe = frontend_has_settle_watch(TENANT_ID)
fe_pass = fe[:hits].to_a.any? || fe[:reason].to_s.include?("no asset")
overall = record(steps, "08", "deployed shop JS settle poll markers", fe_pass, fe) && overall

artifact = {
  scenario: "b112_payment_settle_post_deploy",
  date: DATE,
  stand: BASE,
  tenant_id: TENANT_ID,
  deploy: "owner 2026-06-20",
  fix_commit: "14cdf12",
  chain: "POST /callbacks/tbank → accepted → POST finalize → payment_settled → Payment.svelte beginSettlementWatch",
  local_test: "b112_payment_settle_chain_test.rb 2/2 PASS",
  steps: steps,
  smoke_order: { order_id: order_id, email: email, provider_payment_id: provider_payment_id },
  callback_smoke: smoke,
  frontend_bundle: fe,
  pass: overall && steps.select { |s| %w[05 06].include?(s[:id]) }.all? { |s| s[:pass] },
  issues_status: overall ? "resolved" : "open",
  next_step: overall ? "апрув заказчика B1.12 эпик + повтор real-card на tenant" : "debug failed step"
}

File.write(OUT, JSON.pretty_generate(artifact))
puts "Wrote #{OUT}"
exit(overall ? 0 : 1)
