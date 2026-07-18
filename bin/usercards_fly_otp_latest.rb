#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

EMAIL = ENV.fetch("UC_EMAIL", "aramfifa100@gmail.com")
FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")

out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
raise "fly machine list failed" unless status.success?

machines = JSON.parse(out)
web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
web ||= machines.find { |m| m["state"] == "started" }
machine_id = web&.dig("id") || raise("no started fly machine")

ruby_line = <<~RUBY.gsub(/\s+/, " ").strip
  require 'json';
  email = #{EMAIL.inspect};
  rec = ShopEmailOtpCode.where(email: email, is_used: false).where('expires_at > ?', Time.current).order(created_at: :desc).first;
  puts JSON.generate({ email: email, code: rec&.code, expires_at: rec&.expires_at&.utc&.iso8601 })
RUBY

shell_cmd = "/rails/bin/rails runner #{ruby_line.inspect}"
raw, err, st = Open3.capture3(FLY_BIN, "machine", "exec", machine_id, "-a", FLY_APP, shell_cmd)
raise "runner failed: #{err}" unless st.success?

body = raw.strip.lines.reject { |l| l.start_with?("Exit code:") || l.start_with?("Connecting to") }.join("\n").strip
puts body
