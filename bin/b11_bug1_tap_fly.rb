#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

ROOT = File.expand_path("..", __dir__)
prep = JSON.parse(File.read(File.join(ROOT, "tmp/b11_bug1_guest_ws_prep.json")))
cfg = File.expand_path("~/.fly/config.yml")
ENV["FLY_API_TOKEN"] = File.read(cfg)[/access_token:\s*(.+)/, 1]&.strip if File.exist?(cfg)

FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")
FLY_APP = "coffeeos"
oid = prep["order_id"]

out, = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
mid = JSON.parse(out).find { |m| m["state"] == "started" }&.dig("id") || raise("no machine")

ruby = "barista = User.find_by!(email: 'barista-a@demo.coffeeos.local'); order = Order.find('#{oid}'); Barista::OrderStatusUpdateService.new(order: order, new_status: 'preparing', user_id: barista.id).call!; puts order.reload.status"

remote_cmd = "/rails/bin/rails runner #{ruby.inspect}"
out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", mid, "-a", FLY_APP, remote_cmd)
puts out
warn err unless err.empty?
exit(st.success? ? 0 : 1)
