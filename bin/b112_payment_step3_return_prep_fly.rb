#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.12 bug шаг 3 — prep Fly: 3DS return-path (tenant заказчика) → tmp JSON для MCP.
#
#   ruby bin/b112_payment_step3_return_prep_fly.rb
#   node bin/b112_payment_step3_return_mcp.mjs

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
OUT = File.join(ROOT, "tmp/b112_payment_step3_return_prep.json")
DATE = Time.now.utc.strftime("%Y-%m-%d")

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
    puts JSON.generate(order_status: order.status, payment_status: pay.status, payment_settled: order.accepted?)
  RUBY
  raw = fly_runner(ruby.gsub(/\s+/, " ").strip)
  json_line = raw.lines.map(&:strip).reverse.find { |l| l.start_with?("{") && l.include?("order_status") }
  raise "callback parse failed: #{raw[-400..]}" unless json_line

  JSON.parse(json_line)
end

def jar_to_playwright_cookies(jar_path)
  cookies = []
  File.foreach(jar_path) do |line|
    next if line.strip.empty?

    raw = line.chomp
    http_only = false
    if raw.start_with?("#HttpOnly_")
      http_only = true
      raw = raw.delete_prefix("#HttpOnly_")
    elsif raw.start_with?("#")
      next
    end

    parts = raw.split("\t")
    next unless parts.size >= 7

    domain, _flag, path, secure, _expires, name, value = parts
    cookies << {
      name: name,
      value: value,
      domain: domain,
      path: path.empty? ? "/" : path,
      secure: secure == "TRUE",
      httpOnly: http_only
    }
  end
  cookies
end

def first_product_id(tenant_id, jar, headers)
  body, http = curl_get_json("#{BASE}/shop/api/categories?tenant_id=#{tenant_id}", jar, headers: headers)
  raise "categories #{http}" unless http == 200

  cats = body.is_a?(Array) ? body : body["categories"] || body["data"] || []
  product = cats.flat_map { |c| c["products"] || [] }.find { |p| p["id"] && !p["id"].to_s.empty? }
  raise "no products" unless product

  product["id"]
end

def build_payment_session(order_body, config_body)
  {
    order_id: order_body["order_id"],
    total: order_body["total"],
    provider_payment_id: order_body["provider_payment_id"],
    terminal_key: order_body["terminal_key"] || config_body["terminal_key"],
    payment_url: order_body["payment_url"],
    reconnect_token: order_body["reconnect_token"],
    payment_iframe: true,
    payment_method: "card",
    card_binding: order_body["card_binding"] == true,
    integration_script_url: config_body["integration_script_url"],
    payment_started: true
  }
end

def create_card_order!(suffix, tag)
  email = "b112-s3-#{tag}-#{suffix}@coffeeos.dev"
  jar = File.join(Dir.tmpdir, "b112-s3-#{tag}-#{suffix}.cookies")
  api_key = shop_key(TENANT_ID)
  headers = {
    "Accept" => "application/json",
    "Content-Type" => "application/json",
    "X-Shop-Tenant" => TENANT_ID,
    "X-Shop-Api-Key" => api_key
  }

  curl("#{BASE}/shop?tenant_id=#{TENANT_ID}", "-c", jar, "-b", jar, "-o", File::NULL)
  curl_post_json("#{BASE}/shop/api/email_otp/send?tenant_id=#{TENANT_ID}", jar, headers: headers, body: { email: email })
  sleep 2
  code = fetch_otp(email)
  raise "otp failed #{tag}" if code.nil? || code.empty?

  _, verify_http = curl_post_json(
    "#{BASE}/shop/api/email_otp/verify?tenant_id=#{TENANT_ID}",
    jar, headers: headers, body: { email: email, code: code }
  )
  raise "verify failed #{tag}" unless verify_http == 200

  curl("-c", jar, "-b", jar, "-X", "DELETE", "#{BASE}/shop/api/cart?tenant_id=#{TENANT_ID}",
    "-H", "Accept: application/json", "-H", "X-Shop-Api-Key: #{api_key}", "-o", File::NULL)

  product_id = first_product_id(TENANT_ID, jar, headers)
  curl_post_json(
    "#{BASE}/shop/api/cart/add?tenant_id=#{TENANT_ID}",
    jar, headers: headers,
    body: { product_id: product_id, quantity: 1, selected_modifiers: [] }
  )

  order_body, order_http = curl_post_json(
    "#{BASE}/shop/api/orders?tenant_id=#{TENANT_ID}",
    jar, headers: headers,
    body: {
      name: "B112 S3 #{tag}",
      email: email,
      payment_method: "card",
      client_order_uuid: SecureRandom.uuid
    }
  )
  raise "order failed #{tag}: #{order_http}" unless order_http == 200

  config_body, = curl_get_json("#{BASE}/shop/api/config?tenant_id=#{TENANT_ID}", jar, headers: headers)

  {
    email: email,
    jar: jar,
    order_body: order_body,
    payment_session: build_payment_session(order_body, config_body),
    shop_cookies: jar_to_playwright_cookies(jar),
    profile_storage_key: "shop_guest_profile:#{TENANT_ID}",
    name: "B112 S3 #{tag}"
  }
end

load_fly_token!
FileUtils.mkdir_p(File.dirname(OUT))
suffix = Time.now.utc.strftime("%m%d%H%M")

immediate = create_card_order!("immediate", suffix)
cb_immediate = simulate_tbank_callback(
  immediate[:order_body]["order_id"],
  immediate[:order_body]["provider_payment_id"]
)
raise "immediate callback failed" unless cb_immediate["order_status"] == "accepted"

poll = create_card_order!("poll", suffix)

prep = {
  scenario: "b112_payment_step3_return_path",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  fix_commit: "2b15578",
  shop_url: "#{BASE}/shop?tenant_id=#{TENANT_ID}",
  immediate: {
    order_id: immediate[:order_body]["order_id"],
    email: immediate[:email],
    payment_session: immediate[:payment_session],
    shop_cookies: immediate[:shop_cookies],
    profile_storage_key: immediate[:profile_storage_key],
    name: immediate[:name],
    callback: cb_immediate
  },
  poll: {
    order_id: poll[:order_body]["order_id"],
    email: poll[:email],
    provider_payment_id: poll[:order_body]["provider_payment_id"],
    payment_session: poll[:payment_session],
    shop_cookies: poll[:shop_cookies],
    profile_storage_key: poll[:profile_storage_key],
    name: poll[:name]
  }
}

File.write(OUT, JSON.pretty_generate(prep))
puts "Wrote #{OUT}"
