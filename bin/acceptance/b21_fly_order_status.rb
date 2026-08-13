#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

order_id = ARGV.fetch(0)
fly_bin = ENV.fetch("FLY_BIN", "flyctl")
app = ENV.fetch("FLY_APP", "coffeeos")

out, status = Open3.capture2(fly_bin, "machine", "list", "-a", app, "--json")
raise "fly machine list failed" unless status.success?

machines = JSON.parse(out)
mid = (machines.find { |m| m["state"] == "started" } || machines.first)["id"]
ruby = "puts Order.find(#{order_id.inspect}).status"
remote = "/rails/bin/rails runner #{ruby.inspect}"
out, err, st = Open3.capture3(fly_bin, "machine", "exec", mid, "-a", app, remote)
puts [out, err].join
exit(st.success? ? 0 : 1)
