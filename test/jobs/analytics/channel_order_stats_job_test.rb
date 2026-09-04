# frozen_string_literal: true

require "test_helper"

class Analytics::ChannelOrderStatsJobTest < ActiveJob::TestCase
  include TestFactories

  setup do
    create_tenant!(name: "Job Stats Point", slug: "job-stats-#{SecureRandom.hex(3)}")
  end

  test "perform runs collector without Telegram" do
    assert_no_enqueued_jobs(only: TelegramAlertJob) do
      Analytics::ChannelOrderStatsJob.perform_now
    end
  end
end
