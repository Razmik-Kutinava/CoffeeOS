#!/usr/bin/env ruby
# frozen_string_literal: true

# Sentry 24h gate — unresolved issues in last 24 hours (CoffeeOS ruby project).
#
# Auth: SENTRY_AUTH_TOKEN (Bearer) from https://llc-manageengine.sentry.io/settings/account/api/auth-tokens/
# Cursor agent alternative: plugin-sentry-sentry MCP search_issues / search_events.
#
#   ruby bin/acceptance/sentry_24h_check.rb
#   OUT=docs/operations/milestones/veha_2/artifacts/sentry/sentry_24h_2026-08-31.json ruby bin/acceptance/sentry_24h_check.rb

require "json"
require "net/http"
require "uri"
require "fileutils"

SENTRY_HOST = ENV.fetch("SENTRY_HOST", "https://de.sentry.io")
ORG = ENV.fetch("SENTRY_ORG", "llc-manageengine")
PROJECT = ENV.fetch("SENTRY_PROJECT", "ruby")
DATE = Time.now.utc.strftime("%Y-%m-%d")
OUT = ENV.fetch(
  "OUT",
  File.expand_path("../../docs/operations/milestones/veha_2/artifacts/sentry/sentry_24h_#{DATE}.json", __dir__)
)

QUERIES = [
  { id: "unresolved_last_24h", query: "is:unresolved lastSeen:-24h" },
  { id: "first_seen_24h", query: "firstSeen:-24h" }
].freeze

def sentry_get(path, query: {})
  token = ENV["SENTRY_AUTH_TOKEN"].to_s.strip
  raise "SENTRY_AUTH_TOKEN missing — use MCP plugin-sentry-sentry or export token" if token.empty?

  uri = URI("#{SENTRY_HOST}#{path}")
  uri.query = URI.encode_www_form(query) unless query.empty?

  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Content-Type"] = "application/json"

  res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
  raise "Sentry HTTP #{res.code}: #{res.body.to_s[0, 200]}" unless res.is_a?(Net::HTTPSuccess)

  JSON.parse(res.body)
end

def fetch_issues(query)
  sentry_get(
    "/api/0/projects/#{ORG}/#{PROJECT}/issues/",
    query: { query: query, statsPeriod: "24h" }
  )
end

FileUtils.mkdir_p(File.dirname(OUT))

results = {}
QUERIES.each do |spec|
  list = fetch_issues(spec[:query])
  results[spec[:id]] = {
    "query" => spec[:query],
    "count" => list.length,
    "issues" => list.map do |i|
      {
        "id" => i["id"],
        "short_id" => i["shortId"],
        "title" => i["title"],
        "status" => i["status"],
        "level" => i["level"],
        "last_seen" => i["lastSeen"],
        "first_seen" => i["firstSeen"],
        "count" => i["count"],
        "user_count" => i["userCount"],
        "permalink" => i["permalink"]
      }
    end
  }
end

unresolved = results["unresolved_last_24h"]["count"]
meta = {
  "task" => "sentry_24h_check",
  "date" => DATE,
  "at" => Time.now.utc.iso8601,
  "org" => ORG,
  "project" => PROJECT,
  "sentry_host" => SENTRY_HOST,
  "method" => "sentry_api",
  "head" => `git rev-parse --short HEAD`.strip,
  "queries" => results,
  "unresolved_last_24h" => unresolved,
  "first_seen_24h" => results["first_seen_24h"]["count"],
  "status" => unresolved.zero? ? "PASS" : "FAIL",
  "note" => unresolved.zero? ? "clean — no unresolved issues in 24h" : "unresolved issues present"
}

File.write(OUT, JSON.pretty_generate(meta))
puts JSON.pretty_generate(meta)
puts "written #{OUT}"
exit(meta["status"] == "PASS" ? 0 : 1)
