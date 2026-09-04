# frozen_string_literal: true

require "test_helper"

class Analytics::ChannelOrderStatsCollectorTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!(name: "Stats Point", slug: "stats-point-#{SecureRandom.hex(3)}")
    @other = create_tenant!(name: "Other Point", slug: "other-point-#{SecureRandom.hex(3)}")
    @now = Time.zone.parse("2026-09-04 12:00:00")
  end

  test "logs per-source counts for active sales points with open_now flag" do
    travel_to @now do
      create_order!(tenant: @tenant, source: "mobile", created_at: 5.minutes.ago)
      create_order!(tenant: @tenant, source: "mobile", created_at: 10.minutes.ago)
      create_order!(tenant: @tenant, source: "kiosk", created_at: 3.minutes.ago)
      create_order!(tenant: @tenant, source: "manual", created_at: 20.minutes.ago) # вне окна
      create_order!(tenant: @other, source: "app", created_at: 2.minutes.ago)

      lines = capture_info_logs do
        result = Analytics::ChannelOrderStatsCollector.call(now: @now)
        assert result.tenants_logged >= 2
        assert_equal 15, result.window_minutes
      end

      payloads = lines.filter_map do |line|
        match = line.to_s.match(/\[ChannelOrderStats\]\s+(\{.+\})\s*\z/)
        next unless match

        JSON.parse(match[1])
      end
      by_tenant = payloads.index_by { |p| p["tenant_id"] }

      mine = by_tenant[@tenant.id]
      assert mine, "expected log line for tenant #{@tenant.id}"
      assert_equal "ChannelOrderStats", mine["event"]
      assert_equal 15, mine["window_minutes"]
      assert mine.key?("open_now")
      assert_equal true, [ true, false ].include?(mine["open_now"])
      assert_equal 2, mine["counts"]["mobile"]
      assert_equal 1, mine["counts"]["kiosk"]
      assert_equal 0, mine["counts"]["manual"]
      assert_equal 0, mine["counts"]["app"]

      other = by_tenant[@other.id]
      assert other, "expected log line for tenant #{@other.id}"
      assert_equal 1, other["counts"]["app"]
      assert_equal 0, other["counts"]["mobile"]
    end
  end

  test "does not enqueue Telegram alerts" do
    travel_to @now do
      create_order!(tenant: @tenant, source: "mobile", created_at: 1.minute.ago)

      assert_no_enqueued_jobs(only: TelegramAlertJob) do
        Analytics::ChannelOrderStatsCollector.call(now: @now)
      end
    end
  end

  private

  def capture_info_logs
    io = StringIO.new
    previous = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    io.string.lines.map(&:chomp)
  ensure
    Rails.logger = previous
  end

  def create_order!(tenant:, source:, created_at:)
    Order.create!(
      tenant: tenant,
      source: source,
      status: "accepted",
      order_number: "S-#{SecureRandom.hex(3)}",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: created_at,
      updated_at: created_at
    )
  end
end
