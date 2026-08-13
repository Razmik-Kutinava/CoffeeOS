#!/usr/bin/env ruby
# frozen_string_literal: true

# Смена статуса заказа на Fly (как бариста) для stage3 скринов.
#   ruby bin/acceptance/b21_stage3_fly_status.rb preparing|ready [order_id]

require "json"
require "open3"

prep = JSON.parse(File.read("tmp/b21_stage3_guest_prep.json"))
order_id = ARGV[1] || prep["order_id"]
status = ARGV.fetch(0) { raise "usage: b21_stage3_fly_status.rb preparing|ready [order_id]" }
barista_email = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
fly_bin = ENV.fetch("FLY_BIN", "flyctl")
app = ENV.fetch("FLY_APP", "coffeeos")

ruby = [
  "order = Order.find(#{order_id.inspect})",
  "user = User.find_by!(email: #{barista_email.inspect})",
  "Current.tenant_id = order.tenant_id",
  "Current.user_id = user.id",
  "Barista::OrderStatusUpdateService.new(order: order, new_status: #{status.inspect}, user_id: user.id).call!",
  "puts order.reload.status"
].join("; ")

out, status_list = Open3.capture2(fly_bin, "machine", "list", "-a", app, "--json")
raise "fly machine list failed" unless status_list.success?

machines = JSON.parse(out)
mid = (machines.find { |m| m["state"] == "started" } || machines.first)["id"]
remote = "/rails/bin/rails runner #{ruby.inspect}"
out, err, st = Open3.capture3(fly_bin, "machine", "exec", mid, "-a", app, remote)
combined = [ out, err ].join.strip
raise "fly status update failed: #{combined}" unless st.success? && combined.match?(/\b(preparing|ready|accepted)\b/)

puts "order #{order_id} -> #{combined.lines.last&.strip}"
