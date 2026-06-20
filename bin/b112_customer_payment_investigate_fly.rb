#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.12 — шаг 0/1: repro tenant заказчика + снимок заказов/webhook на Fly.
#
#   ruby bin/b112_customer_payment_investigate_fly.rb
#
# → docs/operations/milestones/veha_2/artifacts/demo-feedback/b112_customer_payment_investigate_YYYY-MM-DD.json

require "json"
require "open3"
require "fileutils"
require "tmpdir"
require "securerandom"

ROOT = File.expand_path("..", __dir__)
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
TENANT_ID = ENV.fetch("B112_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(
  ROOT,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b112_customer_payment_investigate_#{DATE}.json"
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
  raise "curl failed" unless status.success?

  out
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

def db_snapshot(tenant_id)
  ruby = <<~RUBY
    tid = #{tenant_id.inspect};
    orders = Order.where(tenant_id: tid, source: :mobile)
      .where("created_at >= ?", 7.days.ago)
      .order(created_at: :desc)
      .limit(15)
      .includes(:payments);
    rows = orders.map do |o|
      pay = o.payments.order(created_at: :desc).first;
      {
        id: o.id,
        status: o.status,
        final_amount: o.final_amount.to_f,
        created_at: o.created_at.iso8601,
        customer_id: o.customer_id,
        payment_status: pay&.status,
        payment_method: pay&.method,
        provider_payment_id: pay&.provider_payment_id,
        provider: pay&.provider
      }
    end;
    pending = rows.count { |r| r[:status] == "pending_payment" };
    accepted = rows.count { |r| r[:status] == "accepted" };
    cards = MobilePaymentMethod.joins("INNER JOIN mobile_customers mc ON mc.id = mobile_payment_methods.customer_id")
      .where("EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = mc.id AND o.tenant_id = ?)", tid)
      .count;
    puts JSON.generate(recent_orders: rows, counts: { pending_payment: pending, accepted: accepted, saved_cards_linked: cards })
  RUBY
  JSON.parse(fly_runner(ruby.gsub(/\s+/, " ").strip))
end

def first_product_id(tenant_id, jar, headers)
  body, http = curl_get_json("#{BASE}/shop/api/categories?tenant_id=#{tenant_id}", jar, headers: headers)
  raise "categories #{http}" unless http == 200

  cats = body.is_a?(Array) ? body : body["categories"] || body["data"] || []
  product = cats.flat_map { |c| c["products"] || [] }.find { |p| p["id"] && !p["id"].to_s.empty? }
  raise "no products" unless product

  product["id"]
end

load_fly_token!
suffix = Time.now.utc.strftime("%m%d%H%M")
email = "b112-inv-#{suffix}@coffeeos.dev"
jar = File.join(Dir.tmpdir, "b112-inv-#{suffix}.cookies")
FileUtils.mkdir_p(File.dirname(OUT))

api_key = shop_key(TENANT_ID)
headers = {
  "Accept" => "application/json",
  "Content-Type" => "application/json",
  "X-Shop-Tenant" => TENANT_ID,
  "X-Shop-Api-Key" => api_key
}

shop_http = curl("-o", File::NULL, "-w", "%{http_code}", "#{BASE}/shop?tenant_id=#{TENANT_ID}")
curl("#{BASE}/shop?tenant_id=#{TENANT_ID}", "-c", jar, "-b", jar, "-o", File::NULL)

config_body, config_http = curl_get_json("#{BASE}/shop/api/config?tenant_id=#{TENANT_ID}", jar, headers: headers)

_, send_http = curl_post_json(
  "#{BASE}/shop/api/email_otp/send?tenant_id=#{TENANT_ID}",
  jar, headers: headers, body: { email: email }
)
sleep 2
code = fetch_otp(email)
raise "otp failed" if code.nil? || code.empty?

_, verify_http = curl_post_json(
  "#{BASE}/shop/api/email_otp/verify?tenant_id=#{TENANT_ID}",
  jar, headers: headers, body: { email: email, code: code }
)

curl("-c", jar, "-b", jar, "-X", "DELETE", "#{BASE}/shop/api/cart?tenant_id=#{TENANT_ID}",
  "-H", "Accept: application/json", "-H", "X-Shop-Api-Key: #{api_key}", "-o", File::NULL)

product_id = first_product_id(TENANT_ID, jar, headers)
_, add_http = curl_post_json(
  "#{BASE}/shop/api/cart/add?tenant_id=#{TENANT_ID}",
  jar, headers: headers,
  body: { product_id: product_id, quantity: 1, selected_modifiers: [] }
)

order_body, order_http = curl_post_json(
  "#{BASE}/shop/api/orders?tenant_id=#{TENANT_ID}",
  jar, headers: headers,
  body: { name: "B112 Investigate", email: email, payment_method: "card", client_order_uuid: SecureRandom.uuid }
)

db = db_snapshot(TENANT_ID)

findings = []
findings << "shop /shop HTTP #{shop_http}" unless shop_http == "200"
findings << "payment_iframe=#{order_body['payment_iframe']} card_binding=#{order_body['card_binding']}" if order_http == 200
findings << "init has payment_url" if order_body["payment_url"].to_s.length.positive?
findings << "R2 flags present on card init" if order_body["payment_iframe"] == true
findings << "pending_payment orders in DB last 7d: #{db.dig('counts', 'pending_payment')}" if db.dig("counts", "pending_payment").to_i.positive?

artifact = {
  scenario: "b112_customer_payment_investigate",
  step: "0-1 repro + DB snapshot",
  date: DATE,
  stand: BASE,
  tenant_id: TENANT_ID,
  customer_report: "b112_customer_payment_stuck_2026-06-19.json",
  started_at: Time.now.utc.iso8601,
  shop: { http: shop_http.to_i },
  config: { http: config_http, terminal_key_present: config_body["terminal_key"].to_s.length.positive?, integration_script_url: config_body["integration_script_url"] },
  smoke_order: {
    email: email,
    http: order_http,
    order_id: order_body["order_id"],
    total: order_body["total"],
    payment_iframe: order_body["payment_iframe"],
    card_binding: order_body["card_binding"],
    payment_url_present: order_body["payment_url"].to_s.length.positive?,
    provider_payment_id: order_body["provider_payment_id"]
  },
  db_last_7_days: db,
  findings: findings,
  hypothesis_step1: [
    "R2 deploy OK on customer tenant (payment_iframe + shell path)",
    "Real 3DS success without finishSuccess — needs step 2 (polling fallback)",
    "Customer screenshot may be CVC error, not post-3DS",
    "Need payment_id from customer for stuck pending orders"
  ],
  needs_customer: ["order_id or payment_id where money was charged", "timestamp of failed attempt"],
  next_step: "go step 2 — Payment.svelte polling finalize while phase=paying",
  pass: shop_http.to_i == 200 && order_http == 200 && order_body["payment_iframe"] == true
}

File.write(OUT, JSON.pretty_generate(artifact))
puts "Wrote #{OUT}"
puts JSON.pretty_generate(artifact)
