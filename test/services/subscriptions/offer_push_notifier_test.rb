# frozen_string_literal: true

require "test_helper"

# TASK_96 [TDD][RED] Subtask 14–21, 29: push-оффер при переходе в shown + push_sent
module Subscriptions
  class OfferPushNotifierTest < ActiveSupport::TestCase
    include TestFactories
    include ActiveJob::TestHelper

    setup do
      @tenant = create_tenant!
      @customer = create_mobile_customer!(email: "opn-#{SecureRandom.hex(4)}@example.com")
      @customer.update!(push_enabled: true, push_token: "fcm-offer-token", push_enabled_at: Time.current,
                        pwa_installed_at: Time.current)
      SubscriptionOfferSetting.create!(
        point_id: @tenant.id,
        enabled: true,
        second_cta_mode: "subscription",
        min_completed_orders: 1,
        required_signals_count: 1
      )
      create_order!(status: :issued)
    end

    def create_order!(status:)
      Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "Guest",
        order_number: "96-#{SecureRandom.hex(3)}",
        source: :mobile,
        status: status,
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100
      )
    end

    def service
      OfferPresentationService.new(customer: @customer, point: @tenant)
    end

    def offer_pushes
      PushNotification.where(customer_id: @customer.id, notification_type: OfferPushNotifier::NOTIFICATION_TYPE)
    end

    def with_stub(klass, method_name, impl)
      original = klass.method(method_name)
      klass.define_singleton_method(method_name, &impl)
      yield
    ensure
      klass.define_singleton_method(method_name, original)
    end

    test "transition to shown with push_enabled_at sends one offer push via existing job" do
      assert_enqueued_with(job: Shop::SendPushNotificationJob) do
        assert_equal true, service.mark_shown
      end

      assert_equal 1, offer_pushes.count
      push = offer_pushes.first
      assert_equal @tenant.id, push.tenant_id
      assert_equal "pending", push.status
      assert push.title.present?
      assert push.body.present?
      url = push.payload["offer_url"]
      assert_match(%r{\A/shop/#/}, url)
      assert_includes url, "offer_channel=push"
      assert_includes url, "utm_campaign=subscription_offer"
      assert_includes url, "utm_content=push_v1"
      assert_includes url, "push_notification_id=#{push.id}"
      assert push.payload["offer_transition_key"].present?
      assert_nil push.payload["order_id"], "offer push must not look like an order-status push"
    end

    test "push_enabled_at nil → no push, state still shown" do
      @customer.update!(push_enabled_at: nil)

      assert_no_enqueued_jobs(only: Shop::SendPushNotificationJob) do
        assert_equal true, service.mark_shown
      end
      assert_equal 0, offer_pushes.count
      assert_equal "shown", SubscriptionOfferState.find_by(customer_id: @customer.id).status
    end

    test "push_token missing → no push" do
      @customer.update!(push_token: nil)
      service.mark_shown
      assert_equal 0, offer_pushes.count
    end

    test "repeated mark_shown for the same transition → push at most once" do
      assert_equal true, service.mark_shown
      assert_equal false, service.mark_shown
      assert_equal false, service.mark_shown
      assert_equal 1, offer_pushes.count
    end

    test "notifier itself is idempotent per transition key" do
      2.times { OfferPushNotifier.call(customer: @customer, point: @tenant, transition_key: "k-1") }
      assert_equal 1, offer_pushes.count

      OfferPushNotifier.call(customer: @customer, point: @tenant, transition_key: "k-2")
      assert_equal 2, offer_pushes.count
    end

    test "re-show after dismiss + 3 orders → new transition → new push" do
      service.mark_shown
      service.mark_dismissed
      3.times { create_order!(status: :issued) }

      travel 1.second do
        assert_equal true, service.mark_shown
      end

      assert_equal 2, offer_pushes.count
      keys = offer_pushes.map { |p| p.payload["offer_transition_key"] }
      assert_equal 2, keys.uniq.size
    end

    test "purchased → no offer push" do
      SubscriptionOfferState.create!(customer_id: @customer.id, status: "purchased")
      assert_not service.mark_shown
      assert_equal 0, offer_pushes.count
    end

    test "GrowthPromo available → no shown and no push" do
      PointCampaignSetting.create!(
        point_id: @tenant.id,
        campaign_type: PointCampaignSetting::CAMPAIGN_CARD_BINDING_PROMO,
        enabled: true,
        threshold: 1000,
        counter: 0,
        config: { "promo_amount_rub" => 11 }
      )
      assert_not service.mark_shown
      assert_equal 0, offer_pushes.count
      assert_not SubscriptionOfferState.find_by(customer_id: @customer.id)&.shown?
    end

    test "notifier error is swallowed — mark_shown still succeeds" do
      with_stub(PushNotification, :create!, ->(*_a, **_k) { raise StandardError, "boom" }) do
        assert_nothing_raised { assert_equal true, service.mark_shown }
      end
      assert_equal "shown", SubscriptionOfferState.find_by(customer_id: @customer.id).status
    end

    test "job: FCM error → notification failed, no push_sent, no raise" do
      service.mark_shown
      push = offer_pushes.first

      with_stub(Shop::FcmClient, :deliver!, ->(**_k) { raise Shop::FcmClient::Error, "FCM v1 500" }) do
        assert_nothing_raised { Shop::SendPushNotificationJob.perform_now(push.id) }
      end

      assert_equal "failed", push.reload.status
      assert_equal 0, MarketingEvent.where(customer_id: @customer.id, event_type: "push_sent").count
    end

    test "job: successful delivery of offer push → push_sent event" do
      service.mark_shown
      push = offer_pushes.first

      with_stub(Shop::FcmClient, :deliver!, ->(**_k) { { "name" => "ok" } }) do
        Shop::SendPushNotificationJob.perform_now(push.id)
      end

      assert_equal "sent", push.reload.status
      event = MarketingEvent.find_by(customer_id: @customer.id, event_type: "push_sent")
      assert event, "push_sent expected"
      assert_equal "push", event.channel
      assert_equal @tenant.id, event.point_id
      assert_equal push.id, event.metadata["push_notification_id"]
    end

    test "job: order-status push delivery does not create marketing events" do
      order = create_order!(status: :accepted)
      push = PushNotification.create!(
        customer_id: @customer.id, tenant_id: @tenant.id, notification_type: "order_status",
        title: "Заказ", body: "b", payload: { "order_id" => order.id }, status: :pending
      )

      with_stub(Shop::FcmClient, :deliver!, ->(**_k) { { "name" => "ok" } }) do
        Shop::SendPushNotificationJob.perform_now(push.id)
      end

      assert_equal "sent", push.reload.status
      assert_equal 0, MarketingEvent.where(customer_id: @customer.id).count
    end
  end
end
