#!/usr/bin/env ruby
# frozen_string_literal: true

# Fetch latest active ShopEmailOtpCode from Fly (for MCP scripts).
# Usage: ruby bin/fly-tools/fetch_fly_otp.rb email@example.com

require "json"
require "open3"

email = ARGV[0].to_s.strip
abort "usage: ruby bin/fly-tools/fetch_fly_otp.rb EMAIL" if email.empty?

FLY_APP = ENV.fetch("FLY_APP", "coffeeos")
FLY_BIN = ENV.fetch("FLY_BIN", "flyctl")

def load_fly_token!
  return if ENV["FLY_API_TOKEN"] && !ENV["FLY_API_TOKEN"].empty?

  cfg = File.expand_path("~/.fly/config.yml")
  return unless File.exist?(cfg)

  token = File.read(cfg)[/access_token:\s*(.+)/, 1]&.strip
  ENV["FLY_API_TOKEN"] = token if token && !token.empty?
end

def fly_machine_id
  out, status = Open3.capture2(FLY_BIN, "machine", "list", "-a", FLY_APP, "--json")
  raise "fly machine list failed" unless status.success?

  machines = JSON.parse(out)
  machines.find { |m| m["state"] == "started" }&.dig("id") || machines.first&.dig("id") || raise("no fly machine")
end

load_fly_token!
ruby = "puts ShopEmailOtpCode.active(#{email.inspect}).order(created_at: :desc).limit(1).pick(:code) || 'NONE'"
out, err, status = Open3.capture3(
  FLY_BIN, "machine", "exec", fly_machine_id, "-a", FLY_APP,
  "/rails/bin/rails runner #{ruby.inspect}"
)
text = [out, err].join
code = text.scan(/\b(\d{6})\b/).last&.first
if code && code != "NONE"
  puts code
  exit 0
end

warn text unless text.strip.empty?
exit 1
