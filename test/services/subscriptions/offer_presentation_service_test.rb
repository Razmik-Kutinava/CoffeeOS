# frozen_string_literal: true

require "test_helper"

# TASK_95 [TDD][RED] Subtask 4–17: OfferPresentationService — presentation + переходы
module Subscriptions
  class OfferPresentationServiceTest < ActiveSupport::TestCase
    include TestFactories

    setup do
      @tenant = create_tenant!
      @customer = create_mobile_customer!(email: "ops-#{SecureRandom.hex(4)}@example.com")
      SubscriptionOfferSetting.create!(
        point_id: @tenant.id,
        enabled: true,
        second_cta_mode: "subscription",
        min_completed_orders: 1,
        required_signals_count: 1
      )
      create_order!(status: :issued)
      @customer.update!(pwa_installed_at: Time.current)
    end

    def create_order!(status:, tenant: @tenant)
      Order.create!(
        tenant_id: tenant.id,
        customer_id: @customer.id,
        customer_name: "Guest",
        order_number: "95-#{SecureRandom.hex(3)}",
        source: :mobile,
        status: status,
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100
      )
    end

    def enable_growth_promo!
      PointCampaignSetting.create!(
        point_id: @tenant.id,
        campaign_type: PointCampaignSetting::CAMPAIGN_CARD_BINDING_PROMO,
        enabled: true,
        threshold: 1000,
        counter: 0,
        config: { "promo_amount_rub" => 11 }
      )
    end

    def service(point: @tenant)
      OfferPresentationService.new(customer: @customer, point: point)
    end

    def state
      SubscriptionOfferState.find_by(customer_id: @customer.id)
    end

    test "not_shown + eligible + no promo → banner and push, no unread" do
      result = service.call
      assert_equal true, result[:should_show_banner]
      assert_equal true, result[:should_show_push]
      assert_equal false, result[:has_unread_offer_in_lk]
    end

    test "not eligible → no banner" do
      @customer.update!(pwa_installed_at: nil)
      assert_equal false, service.call[:should_show_banner]
    end

    test "GrowthPromo available blocks banner" do
      enable_growth_promo!
      assert Payments::GrowthPromo.available?(@customer, @tenant)
      result = service.call
      assert_equal false, result[:should_show_banner]
      assert_equal false, result[:should_show_push]
    end

    test "GrowthPromo exhausted no longer blocks banner" do
      enable_growth_promo!
      Payments::GrowthPromo.mark_used!(
        phone: @customer.phone, method_hash: "hash-95-ops", method_type: "card",
        customer_id: @customer.id, tenant_id: @tenant.id
      )
      assert_equal true, service.call[:should_show_banner]
    end

    test "mark_shown: not_shown → shown, first_shown_at + unread_since, unread on, banner off" do
      service.mark_shown
      assert_equal "shown", state.status
      assert state.first_shown_at.present?
      assert state.unread_since.present?

      result = service.call
      assert_equal false, result[:should_show_banner]
      assert_equal true, result[:has_unread_offer_in_lk]
    end

    test "mark_shown is a no-op while GrowthPromo available" do
      enable_growth_promo!
      service.mark_shown
      assert(state.nil? || state.not_shown?)
    end

    test "mark_shown twice keeps first_shown_at" do
      service.mark_shown
      first = state.first_shown_at
      travel 1.hour do
        service.mark_shown
        assert_equal first.to_i, state.first_shown_at.to_i
      end
    end

    test "mark_dismissed: shown → dismissed with timestamp and completed orders snapshot" do
      service.mark_shown
      service.mark_dismissed
      assert_equal "dismissed", state.status
      assert state.last_dismissed_at.present?
      assert_equal 1, state.completed_orders_count_at_dismissal
    end

    test "mark_dismissed from not_shown does not start a cycle" do
      service.mark_dismissed
      assert(state.nil? || state.not_shown?)
    end

    test "dismissed: no banner before 3 new completed orders, unread stays; banner after 3" do
      service.mark_shown
      service.mark_dismissed

      2.times { create_order!(status: :issued) }
      result = service.call
      assert_equal false, result[:should_show_banner]
      assert_equal true, result[:has_unread_offer_in_lk]

      create_order!(status: :closed)
      assert_equal true, service.call[:should_show_banner]
    end

    test "repeat mark_shown after 3 orders starts new cycle without old snapshot" do
      service.mark_shown
      service.mark_dismissed
      3.times { create_order!(status: :issued) }

      service.mark_shown
      assert_equal "shown", state.status
      assert_nil state.completed_orders_count_at_dismissal
      assert_equal false, service.call[:should_show_banner]
    end

    test "mark_viewed_in_lk clears unread and moves to viewed_in_lk; idempotent" do
      service.mark_shown
      service.mark_viewed_in_lk
      assert_equal "viewed_in_lk", state.status
      assert_nil state.unread_since
      assert_equal false, service.call[:has_unread_offer_in_lk]

      service.mark_viewed_in_lk
      assert_equal "viewed_in_lk", state.status
    end

    test "viewed_in_lk without new show keeps unread off" do
      service.mark_shown
      service.mark_viewed_in_lk
      create_order!(status: :issued)
      assert_equal false, service.call[:has_unread_offer_in_lk]
    end

    test "mark_viewed_in_lk before any show does not change not_shown" do
      service.mark_viewed_in_lk
      assert(state.nil? || state.not_shown?)
      assert_equal true, service.call[:should_show_banner]
    end

    test "viewed after dismiss still re-shows banner after 3 new orders" do
      service.mark_shown
      service.mark_dismissed
      service.mark_viewed_in_lk
      3.times { create_order!(status: :issued) }
      assert_equal true, service.call[:should_show_banner]
    end

    test "mark_purchased! → purchased, banner and unread off" do
      service.mark_shown
      OfferPresentationService.mark_purchased!(customer_id: @customer.id)

      assert_equal "purchased", state.status
      assert_nil state.unread_since
      result = service.call
      assert_equal false, result[:should_show_banner]
      assert_equal false, result[:should_show_push]
      assert_equal false, result[:has_unread_offer_in_lk]
    end

    test "purchased blocks offer on any point regardless of eligibility" do
      other = create_tenant!
      SubscriptionOfferSetting.create!(
        point_id: other.id, enabled: true, second_cta_mode: "subscription",
        min_completed_orders: 1, required_signals_count: 1
      )
      create_order!(status: :issued, tenant: other)
      OfferPresentationService.mark_purchased!(customer_id: @customer.id)

      result = service(point: other).call
      assert_equal false, result[:should_show_banner]
      assert_equal false, result[:has_unread_offer_in_lk]
    end

    test "reshow counts 3 new completed orders on the current point, not a snapshot from another point" do
      other = create_tenant!
      SubscriptionOfferSetting.create!(
        point_id: other.id, enabled: true, second_cta_mode: "subscription",
        min_completed_orders: 1, required_signals_count: 1
      )
      4.times { create_order!(status: :issued) }
      service.mark_shown
      service.mark_dismissed
      assert_equal 5, state.completed_orders_count_at_dismissal

      create_order!(status: :issued, tenant: other)
      assert_equal false, service(point: other).call[:should_show_banner]

      2.times { create_order!(status: :issued, tenant: other) }
      assert_equal true, service(point: other).call[:should_show_banner]
    end

    test "active subscriber without offer state gets no banner and no unread" do
      plan = SubscriptionPlan.create!(
        code: "ops_#{SecureRandom.hex(2)}", price: 99, currency: "RUB", period_days: 7,
        drink_limit: 5, discount_price_per_drink: 119, over_limit_discount_percent: 20, active: true
      )
      sub = Subscription.new(customer_id: @customer.id, plan_id: plan.id, purchase_point_id: @tenant.id, status: :active)
      sub.start_period_from_plan!(plan)
      sub.save!

      assert_nil state
      result = service.call
      assert_equal false, result[:should_show_banner]
      assert_equal false, result[:has_unread_offer_in_lk]
    end

    test "purchased is terminal for shown/dismissed/viewed" do
      OfferPresentationService.mark_purchased!(customer_id: @customer.id)
      service.mark_shown
      service.mark_dismissed
      service.mark_viewed_in_lk
      assert_equal "purchased", state.status
    end
  end
end
