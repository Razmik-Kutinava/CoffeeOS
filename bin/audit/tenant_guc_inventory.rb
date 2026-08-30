#!/usr/bin/env ruby
# frozen_string_literal: true

# IB Phase 3 — static inventory of tenant GUC and row_security off usage.
# Exit 0 always (informational; does not fail CI unless wired explicitly later).

require "pathname"

ROOT = Pathname.new(__dir__).join("..", "..").expand_path

PATTERNS = {
  "SET LOCAL app.current_tenant_id" => /SET\s+LOCAL\s+app\.current_tenant_id/i,
  "SET LOCAL app.current_user_id" => /SET\s+LOCAL\s+app\.current_user_id/i,
  "row_security off" => /SET\s+LOCAL\s+row_security\s*=\s*off/i,
  "set_pg_context" => /\bset_pg_context\b/,
  "Current.tenant_id =" => /Current\.tenant_id\s*=/
}.freeze

SKIP_DIRS = %w[
  node_modules vendor/bundle tmp log storage .git
].freeze

def ruby_files
  Dir.glob(ROOT.join("{app,lib,bin,test,db}/**/*.{rb,rake}")).reject do |path|
    SKIP_DIRS.any? { |d| path.include?("/#{d}/") }
  end.sort
end

def scan
  files = ruby_files
  hits = PATTERNS.transform_values { {} }

  files.each do |file|
    rel = Pathname.new(file).relative_path_from(ROOT).to_s
    lines = File.readlines(file, chomp: true)
    lines.each_with_index do |line, idx|
      PATTERNS.each do |label, regex|
        next unless line.match?(regex)

        hits[label][rel] ||= []
        hits[label][rel] << idx + 1
      end
    end
  end

  { files: files.size, hits: hits }
end

def print_report(result)
  puts "CoffeeOS tenant GUC inventory"
  puts "Root: #{ROOT}"
  puts "Ruby files scanned: #{result[:files]}"
  puts "---"

  result[:hits].each do |label, by_file|
    count = by_file.values.sum(&:size)
    puts "\n## #{label} (#{count} occurrences in #{by_file.size} files)"
    by_file.sort.each do |file, line_nums|
      puts "  #{file}:#{line_nums.join(',')}"
    end
  end

  puts "\n---"
  puts "BACKLOG (Phase 3 SKIP — see docs/product/security/phase_3_tenant_rls/RLS_TENANT_AUDIT.md):"
  %w[
    app/controllers/kiosk/api/auth_controller.rb
    app/controllers/tv_boards_controller.rb
    app/channels/application_cable/connection.rb
  ].each { |f| puts "  SKIP #{f}" }

  puts "\nExit 0 (informational audit)."
end

print_report(scan)
exit 0
