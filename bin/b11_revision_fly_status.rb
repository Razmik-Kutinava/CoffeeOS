#!/usr/bin/env ruby
# frozen_string_literal: true

# Смена статуса заказа B1.1 revision на Fly.
#   ruby bin/b11_revision_fly_status.rb accept_payment|preparing|ready [order_id]
#
# accept_payment — pending_payment → accepted (Callbacks::PaymentStatusUpdater)

require "json"
require "open3"

prep_path = "tmp/b11_revision_fly_prep.json"
prep = File.exist?(prep_path) ? JSON.parse(File.read(prep_path)) : {}
order_id = ARGV[1] || prep["order_id"]
action = ARGV.fetch(0) { raise "usage: b11_revision_fly_status.rb accept_payment|preparing|ready [order_id]" }
barista_email = ENV.fetch("B21_BARISTA_EMAIL", "barista-a@demo.coffeeos.local")
fly_bin = ENV.fetch("FLY_BIN", "flyctl")
app = ENV.fetch("FLY_APP", "coffeeos")

ruby = case action
       when "accept_payment"
         [
           "order = Order.find(#{order_id.inspect})",
           "payment = order.payments.order(created_at: :desc).first",
           "raise 'no payment' unless payment",
           "Callbacks::PaymentStatusUpdater.new(payment: payment, new_status: 'succeeded', note: 'b11_revision_fly').call!",
           "puts order.reload.status"
         ].join("; ")
       when "preparing", "ready"
         [
           "order = Order.find(#{order_id.inspect})",
           "user = User.find_by!(email: #{barista_email.inspect})",
           "Current.tenant_id = order.tenant_id",
           "Current.user_id = user.id",
           "Barista::OrderStatusUpdateService.new(order: order, new_status: #{action.inspect}, user_id: user.id).call!",
           "puts order.reload.status"
         ].join("; ")
       else
         raise "unknown action: #{action}"
       end

out, status_list = Open3.capture2(fly_bin, "machine", "list", "-a", app, "--json")
raise "fly machine list failed" unless status_list.success?

machines = JSON.parse(out)
mid = (machines.find { |m| m["state"] == "started" } || machines.first)["id"]
remote = "/rails/bin/rails runner #{ruby.inspect}"
out, err, st = Open3.capture3(fly_bin, "machine", "exec", mid, "-a", app, remote)
combined = [out, err].join.strip
raise "fly status update failed: #{combined}" unless st.success?

puts "order #{order_id} #{action} -> #{combined.lines.last&.strip}"
