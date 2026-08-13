#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

root = File.expand_path("../..", __dir__)
json_path = File.join(root, "config/secrets/firebase-service-account.json")
env_path = File.join(root, ".env")

j = JSON.generate(JSON.parse(File.read(json_path)))
lines = File.readlines(env_path, chomp: false)
head = lines.take_while { |l| !l.start_with?("FIREBASE_SERVICE_ACCOUNT_JSON") }
File.write(env_path, head.join + "FIREBASE_SERVICE_ACCOUNT_JSON=#{j}\n")
puts "OK: #{env_path}"
