#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["SKIP_TENANTS"] = "1"
ENV["SKIP_STRESS"] = "0"
ENV["STRESS_OFFSET"] = "4"
ENV["STRESS_ROUNDS"] = "8"
ENV["OUT"] = "docs/operations/milestones/veha_2/artifacts/prog10_stress_wave2.json"
load File.expand_path("prog10_fly_smoke.rb", __dir__)
