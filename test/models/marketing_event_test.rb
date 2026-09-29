# frozen_string_literal: true

require "test_helper"

# TASK_96 [TDD][RED] Subtask 22: журнал маркетинговых событий оффера
class MarketingEventTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "me-#{SecureRandom.hex(4)}@example.com")
  end

  test "stores funnel fields incl. metadata jsonb" do
    event = MarketingEvent.create!(
      event_type: "offer_opened",
      customer_id: @customer.id,
      point_id: @tenant.id,
      utm_campaign: "subscription_offer",
      utm_content: "banner_v1",
      channel: "banner",
      occurred_at: Time.current,
      metadata: { "source" => "test" }
    )

    event.reload
    assert_equal "offer_opened", event.event_type
    assert_equal @customer.id, event.customer_id
    assert_equal @tenant.id, event.point_id
    assert_equal "subscription_offer", event.utm_campaign
    assert_equal "banner_v1", event.utm_content
    assert_equal "banner", event.channel
    assert_equal({ "source" => "test" }, event.metadata)
  end

  test "event_type covers the 7 funnel events" do
    assert_equal %w[banner_shown banner_dismissed lk_viewed offer_opened push_sent push_opened subscription_purchased].sort,
                 MarketingEvent.event_types.keys.sort
  end

  test "unknown event_type is rejected" do
    assert_raises(ArgumentError) { MarketingEvent.new(event_type: "clicked") }
  end

  test "channel limited to banner / lk / push" do
    event = MarketingEvent.new(event_type: "offer_opened", customer_id: @customer.id, occurred_at: Time.current,
                               channel: "email")
    assert_not event.valid?
    event.channel = nil
    assert event.valid?, event.errors.full_messages.inspect
  end

  test "defaults: metadata {} and occurred_at required" do
    event = MarketingEvent.new(event_type: "lk_viewed", customer_id: @customer.id)
    assert_equal({}, event.metadata)
    assert_not event.valid?
    assert event.errors[:occurred_at].any?
  end

  test "logger writes event and never raises on bad input" do
    event = Subscriptions::MarketingEventLogger.log(
      event_type: "banner_dismissed", customer_id: @customer.id, point_id: @tenant.id
    )
    assert event&.persisted?
    assert event.occurred_at.present?

    assert_nothing_raised do
      assert_nil Subscriptions::MarketingEventLogger.log(event_type: "bogus", customer_id: @customer.id)
      assert_nil Subscriptions::MarketingEventLogger.log(event_type: "offer_opened", customer_id: @customer.id,
                                                         channel: "email")
    end
  end

  test "logger failure inside an outer transaction does not abort it" do
    ActiveRecord::Base.transaction do
      assert_nil Subscriptions::MarketingEventLogger.log(event_type: "offer_opened", customer_id: @customer.id,
                                                         channel: "email")
      @customer.update!(first_name: "AfterFailedLog")
    end
    assert_equal "AfterFailedLog", @customer.reload.first_name
  end
end
