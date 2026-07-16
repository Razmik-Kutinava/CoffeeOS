#!/usr/bin/env ruby
# frozen_string_literal: true

# UserCards Фаза 1 post-deploy verify: replay webhook + cards check (без новой оплаты).
#
#   ruby bin/usercards_fly_phase1_verify.rb
#
# → docs/operations/milestones/veha_2/artifacts/usercards_save_card/usercards_fly_phase1_verify_YYYY-MM-DD.json

require "json"
require "open3"
require "fileutils"
require "net/http"
require "uri"

ROOT = File.expand_path("..", __dir__)
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
BASE = ENV.fetch("BASE", "https://coffeeos.fly.dev")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/usercards_save_card/usercards_fly_phase1_verify_#{DATE}.json")

ORDER_ID = ENV.fetch("UC_ORDER_ID", "fc18c88e-a5be-4a6e-a327-3314364053f3")
PAYMENT_ID = ENV.fetch("UC_PAYMENT_ID", "8861552152")
REBILL_ID = ENV.fetch("UC_REBILL_ID", "1846699802")
CARD_ID = ENV.fetch("UC_CARD_ID", "566291000")
PAN = ENV.fetch("UC_PAN", "220196******5953")
EMAIL = ENV.fetch("UC_EMAIL", "aramfifa100@gmail.com")
TENANT_ID = ENV.fetch("UC_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
  web ||= machines.find { |m| m["state"] == "started" }
  web&.dig("id") || raise("no started fly machine")
end

def fly_runner(machine_id, ruby_line)
  shell_cmd = "/rails/bin/rails runner #{ruby_line.inspect}"
  out, err, status = Open3.capture3(FLY_BIN, "machine", "exec", machine_id, "-a", FLY_APP, shell_cmd)
  line = out.strip.lines.reject { |l| l.start_with?("Exit code:") || l.start_with?("Connecting to") }.last&.strip
  raise "runner failed: #{err.lines.last(3).join}" unless status.success? && line

  line
end

def fly_runner_json(machine_id, ruby_line)
  JSON.parse(fly_runner(machine_id, ruby_line))
end

def fly_release
  out, status = Open3.capture2(FLY_BIN, "releases", "-a", FLY_APP, "--json")
  return {} unless status.success?

  rel = JSON.parse(out).first
  {
    version: rel&.dig("Version"),
    status: rel&.dig("Status"),
    image: rel&.dig("ImageRef"),
    created_at: rel&.dig("CreatedAt")
  }
end

def post_webhook(json_body)
  uri = URI.parse("#{BASE}/callbacks/tbank")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 15
  http.read_timeout = 30
  req = Net::HTTP::Post.new(uri.path)
  req["Content-Type"] = "application/json"
  req.body = json_body
  res = http.request(req)
  { http: res.code.to_i, body: JSON.parse(res.body) }
rescue JSON::ParserError
  { http: res.code.to_i, body: { raw: res.body.to_s[0, 500] } }
end

FileUtils.mkdir_p(File.dirname(OUT))
machine_id = fly_machine_id

before = fly_runner_json(
  machine_id,
  "require 'json'; c=MobileCustomer.find_by(email:#{EMAIL.inspect}); puts JSON.generate({email:#{EMAIL.inspect},customer_id:c&.id,cards:c ? MobilePaymentMethod.where(customer_id:c.id,payment_type:'card').map{|m|{id:m.id,pan:m.card_masked,token_present:m.card_token.present?}} : []})"
)

payment_row = fly_runner_json(
  machine_id,
  "require 'json'; p=Payment.joins(:order).where(orders:{id:#{ORDER_ID.inspect}}).first; puts JSON.generate({found:!!p,id:p&.id,status:p&.status,save_card:(p&.provider_data.is_a?(Hash)?p.provider_data['save_card']:nil),provider_payment_id:p&.provider_payment_id})"
)

build_payload_ruby = "require 'json'; base={'TerminalKey'=>ENV.fetch('TBANK_TERMINAL_KEY'),'OrderId'=>#{ORDER_ID.inspect},'PaymentId'=>#{PAYMENT_ID.inspect},'Status'=>'CONFIRMED','Success'=>true,'ErrorCode'=>'0','Amount'=>474,'RebillId'=>#{REBILL_ID.inspect},'CardId'=>#{CARD_ID.inspect},'Pan'=>#{PAN.inspect},'ExpDate'=>'0927','CardType'=>'MIR'}; base['Token']=Payments::TbankAdapter.new.build_token(base); puts JSON.generate(base)"

payload = JSON.parse(fly_runner(machine_id, build_payload_ruby))
webhook = post_webhook(JSON.generate(payload))

after = fly_runner_json(
  machine_id,
  "require 'json'; c=MobileCustomer.find_by(email:#{EMAIL.inspect}); puts JSON.generate({email:#{EMAIL.inspect},customer_id:c&.id,cards:c ? MobilePaymentMethod.where(customer_id:c.id,payment_type:'card').map{|m|{id:m.id,pan:m.card_masked,brand:m.card_brand,token_present:m.card_token.present?,is_default:m.is_default}} : []})"
)

cards_api = fly_runner_json(
  machine_id,
  "require 'json'; c=MobileCustomer.find_by(email:#{EMAIL.inspect}); rows=MobilePaymentMethod.for_customer(c.id).map{|m| Shop::SavedCardJson.serialize(m)}; puts JSON.generate({primary: rows.find{|r| r[:is_default]} || rows.first, cards: rows})"
)

report = {
  date: DATE,
  phase: "1_post_deploy_verify",
  deploy: fly_release,
  method: "replay_webhook_no_new_charge",
  order_id: ORDER_ID,
  payment_id: PAYMENT_ID,
  email: EMAIL,
  tenant_id: TENANT_ID,
  before: before,
  payment: payment_row,
  webhook_request: { http: webhook[:http], body: webhook[:body] },
  after: after,
  cards_api_shape: cards_api,
  pass: after["cards"].is_a?(Array) && after["cards"].any? { |c| c["pan"].to_s.include?("5953") || c["token_present"] },
  cheap_products_note: "Новая оплата не выполнялась — replay webhook CONFIRMED+RebillId (0₽)"
}

File.write(OUT, JSON.pretty_generate(report))
puts "Wrote #{OUT}"
puts "PASS=#{report[:pass]}"
exit(report[:pass] ? 0 : 1)
