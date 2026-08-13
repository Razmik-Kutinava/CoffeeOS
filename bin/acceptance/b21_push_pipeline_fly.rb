#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 push pipeline simulation on Fly — FCM_SIMULATE, без реального устройства.
#   FLY_BIN=flyctl ruby bin/acceptance/b21_push_pipeline_fly.rb

require "json"
require "open3"
require "securerandom"

ROOT = File.expand_path("../..", __dir__)
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = File.join(ROOT, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b21_push_pipeline_sim_#{DATE}.json")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
TENANT_ID = ENV.fetch("B21_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  (machines.find { |m| m["state"] == "started" } || machines.first)["id"]
end

def fly_runner(ruby)
  remote = "/rails/bin/rails runner #{ruby.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP, remote)
  combined = [out, err].join.strip
  raise "fly runner failed: #{combined}" unless st.success?

  combined
end

token = "b21-push-sim-#{SecureRandom.hex(6)}"
email = "b21-push-sim-#{Time.now.to_i}@coffeeos.dev"

sim_ruby = <<~RUBY.gsub(/\s+/, " ").strip
  ENV['FCM_SIMULATE'] = '1';
  tenant = Tenant.find('#{TENANT_ID}');
  customer = MobileCustomer.find_or_initialize_by(email: #{email.inspect});
  customer.update!(first_name: 'Push', last_name: 'Sim', is_active: true, push_enabled: true, push_token: #{token.inspect});
  order = Order.create!(tenant_id: tenant.id, customer_id: customer.id,
    customer_name: 'Push Sim', order_number: '', source: :mobile, status: :accepted,
    total_amount: 100, discount_amount: 0, final_amount: 100);
  order.update!(status: :preparing);
  Shop::OrderStatusPushNotifier.call(order: order.reload, old_status: 'accepted');
  n = PushNotification.where(customer_id: customer.id).order(created_at: :desc).first;
  Shop::SendPushNotificationJob.perform_now(n.id);
  n.reload;
  puts JSON.generate(push_sim: {
    order_id: order.id, notification_id: n.id, body: n.body,
    status: n.status, sent_at: n.sent_at&.iso8601, push_token: customer.push_token
  })
RUBY

whoami, ok = Open3.capture2e("#{FLY_BIN} auth whoami 2>&1")
raise "flyctl auth login required" unless ok.success? && !whoami.strip.empty?

result = {
  task: "b21_push_pipeline_sim",
  run_at: Time.now.utc.iso8601,
  app: FLY_APP,
  tenant_id: TENANT_ID,
  fcm_simulate: true,
  status: "FAIL"
}

begin
  raw = fly_runner(sim_ruby)
  line = raw.lines.find { |l| l.include?("push_sim") } || raw
  payload = JSON.parse(line[/\{.*\}/m] || "{}")
  sim = payload["push_sim"] || payload

  pass = sim["status"] == "sent" &&
         sim["body"].to_s.include?("начали готовить") &&
         !sim["push_token"].to_s.empty?

  result.merge!(
    status: pass ? "PASS" : "FAIL",
    notification: sim,
    checks: {
      push_token: !sim["push_token"].to_s.empty?,
      body_b21: sim["body"].to_s.include?("начали готовить"),
      status_sent: sim["status"] == "sent"
    }
  )
rescue StandardError => e
  result[:error] = "#{e.class}: #{e.message}"
  result[:raw] = raw.to_s[0, 2000] if defined?(raw) && raw
end

File.write(OUT, JSON.pretty_generate(result))
puts JSON.pretty_generate(result)
puts "written #{OUT}"
exit(result[:status] == "PASS" ? 0 : 1)
