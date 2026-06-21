#!/usr/bin/env ruby
# frozen_string_literal: true

# B1.12-R4 — prep Fly: new card inline + one-click, tenant заказчика.
#
#   B112_TENANT_ID=2fdee1ac-4674-41ee-b89e-87b45643f789 ruby bin/b112_r4_single_screen_prep_fly.rb
#   node bin/b112_r4_single_screen_mcp.mjs

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
OUT = File.join(ROOT, "tmp/b112_r4_single_screen_prep.json")
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

def seed_saved_card!(email, rebill_token, masked)
  ruby = <<~RUBY.gsub(/\s+/, " ").strip
    c = MobileCustomer.find_by!(email: #{email.inspect});
    MobilePaymentMethod.where(customer_id: c.id, payment_type: 'card').update_all(is_default: false);
    pm = MobilePaymentMethod.find_or_initialize_by(customer_id: c.id, card_token: #{rebill_token.inspect});
    pm.assign_attributes(card_masked: #{masked.inspect}, card_brand: 'Visa', payment_type: 'card', is_active: true, is_default: true, last_used_at: Time.current);
    pm.save!;
    puts pm.id
  RUBY
  out, err, status = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, "/rails/bin/rails runner #{ruby.inspect}")
  raise "seed card failed: #{err}" unless status.success?

  out.strip.split.last
end

def first_product_id(tenant_id, jar, headers)
  body, http = curl_get_json("#{BASE}/shop/api/categories?tenant_id=#{tenant_id}", jar, headers: headers)
  raise "categories #{http}" unless http == 200

  cats = body.is_a?(Array) ? body : body["categories"] || body["data"] || []
  product = cats.flat_map { |c| c["products"] || [] }.find { |p| p["id"] && !p["id"].to_s.empty? }
  raise "no products" unless product

  product["id"]
end

def setup_guest!(suffix, tag, seed_card: false)
  email = "b112-r4-#{tag}-#{suffix}@coffeeos.dev"
  name = "B112 R4 #{tag}"
  jar = File.join(Dir.tmpdir, "b112-r4-#{tag}-#{suffix}.cookies")
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

  card_id = nil
  saved_label = nil
  if seed_card
    # MobileCustomer создаётся при первом заказе — как в b112_r3_one_click_prep_fly.rb
    cash_body, cash_http = curl_post_json(
      "#{BASE}/shop/api/orders?tenant_id=#{TENANT_ID}",
      jar, headers: headers,
      body: { name: name, email: email, payment_method: "cash", client_order_uuid: SecureRandom.uuid }
    )
    raise "cash order failed #{tag} #{cash_http}" unless cash_http == 200

    masked = "430000******#{suffix[-4..]}"
    rebill = "fly-r4-rebill-#{suffix}"
    card_id = seed_saved_card!(email, rebill, masked)
    saved_body, saved_http = curl_get_json(
      "#{BASE}/shop/api/saved_cards?tenant_id=#{TENANT_ID}&email=#{URI.encode_www_form_component(email)}",
      jar, headers: headers
    )
    raise "saved_cards failed #{tag} #{saved_http}" unless saved_http == 200
    raise "saved_cards primary missing #{tag}" if saved_body.dig("primary", "id").to_s.empty?

    last4 = masked.gsub(/\D/, "")[-4..]
    saved_label = "Visa •••• #{last4}"
    curl_post_json(
      "#{BASE}/shop/api/cart/add?tenant_id=#{TENANT_ID}",
      jar, headers: headers,
      body: { product_id: product_id, quantity: 1, selected_modifiers: [] }
    )
  end

  {
    email: email,
    name: name,
    jar: jar,
    product_id: product_id,
    shop_cookies: jar_to_playwright_cookies(jar),
    saved_card_id: card_id,
    saved_card_label: saved_label
  }
end

load_fly_token!
FileUtils.mkdir_p(File.dirname(OUT))
suffix = Time.now.utc.strftime("%m%d%H%M")

new_card = setup_guest!(suffix, "new", seed_card: false)
one_click = setup_guest!(suffix, "1click", seed_card: true)

prep = {
  scenario: "b112_r4_single_screen",
  date: DATE,
  base: BASE,
  tenant_id: TENANT_ID,
  fix_commit: "75dc252",
  shop_url: "#{BASE}/shop?tenant_id=#{TENANT_ID}",
  checkout_url: "#{BASE}/shop?tenant_id=#{TENANT_ID}#/checkout",
  profile_storage_key: "shop_guest_profile:#{TENANT_ID}",
  new_card: new_card,
  one_click: one_click
}

File.write(OUT, JSON.pretty_generate(prep))
puts "Wrote #{OUT}"
