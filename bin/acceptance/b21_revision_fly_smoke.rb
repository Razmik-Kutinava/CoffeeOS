#!/usr/bin/env ruby
# frozen_string_literal: true

# B2.1 ревизия R3 — Fly smoke (обёртка над b21_barista_board_fly_smoke.rb).
#
#   ruby bin/acceptance/b21_revision_fly_smoke.rb
#   FLY_BIN=flyctl ruby bin/acceptance/b21_revision_fly_smoke.rb

ENV["REVISION"] = "1"
load File.expand_path("b21_barista_board_fly_smoke.rb", __dir__)
