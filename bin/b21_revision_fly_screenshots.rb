#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 ревизия R4 — оркестратор Fly-скринов.
#   FLY_BIN=flyctl ruby bin/b21_revision_fly_screenshots.rb

require "json"

root = File.expand_path("..", __dir__)
prep_script = File.join(root, "bin/b21_revision_fly_prep.rb")
mjs_script = File.join(root, "bin/b21_revision_fly_screenshots.mjs")

prep_ok = system({ "FLY_BIN" => ENV.fetch("FLY_BIN", "flyctl") }, "ruby", prep_script)
abort "prep failed" unless prep_ok

mjs_ok = system("node", mjs_script)
abort "screenshots failed" unless mjs_ok

steps_path = File.join(root, "tmp/b21_revision_fly_screenshots.json")
puts File.read(steps_path) if File.exist?(steps_path)
