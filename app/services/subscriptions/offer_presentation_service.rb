# frozen_string_literal: true

module Subscriptions
  # TASK_95: presentation-состояние оффера подписки (баннер / push / unread в ЛК) и переходы.
  # Eligibility и GrowthPromo только читаются; frontend-флагам не доверяем.
  class OfferPresentationService
    RESHOW_AFTER_COMPLETED_ORDERS = 3

    def self.mark_purchased!(customer_id:)
      state = SubscriptionOfferState.for_customer!(customer_id)
      state.with_lock { state.update!(status: :purchased, unread_since: nil) }
      state
    end

    def initialize(customer:, point:)
      @customer = customer
      @point = point
    end

    def call
      return { should_show_banner: false, should_show_push: false, has_unread_offer_in_lk: false } if subscribed?

      state = current_state
      banner = banner?(state)
      {
        should_show_banner: banner,
        should_show_push: banner,
        has_unread_offer_in_lk: unread?(state)
      }
    end

    def mark_shown
      return unless call[:should_show_banner]

      with_state do |state|
        next if state.shown? || state.purchased?

        now = Time.current
        state.update!(
          status: :shown,
          first_shown_at: state.first_shown_at || now,
          unread_since: state.unread_since || now,
          completed_orders_count_at_dismissal: nil
        )
      end
    end

    def mark_dismissed
      state = current_state
      return unless state&.shown?

      state.with_lock do
        next unless state.shown?

        state.update!(
          status: :dismissed,
          last_dismissed_at: Time.current,
          completed_orders_count_at_dismissal: completed_orders_count
        )
      end
    end

    def mark_viewed_in_lk
      state = current_state
      return unless state

      state.with_lock do
        next if state.purchased? || state.not_shown?

        state.update!(status: :viewed_in_lk, unread_since: nil)
      end
    end

    def mark_purchased
      self.class.mark_purchased!(customer_id: @customer.id)
    end

    private

    def current_state
      SubscriptionOfferState.find_by(customer_id: @customer.id)
    end

    def with_state
      state = SubscriptionOfferState.for_customer!(@customer.id)
      state.with_lock { yield state }
      state
    end

    def banner?(state)
      return false if state&.purchased?
      return false if Payments::GrowthPromo.available?(@customer, @point)
      return false unless Shop::SubscriptionOfferEligibility.check(@customer, @point)
      return true if state.nil? || state.not_shown?

      reshow_due?(state)
    end

    # Снимок completed_orders_count_at_dismissal снят на точке смахивания; сравнивать его со счётчиком
    # другой точки нельзя, поэтому считаем новые завершённые заказы текущей точки после last_dismissed_at.
    def reshow_due?(state)
      return false unless state.dismissed? || state.viewed_in_lk?
      return false if state.completed_orders_count_at_dismissal.nil? || state.last_dismissed_at.nil?

      completed_orders_since(state.last_dismissed_at) >= RESHOW_AFTER_COMPLETED_ORDERS
    end

    def completed_orders_since(time)
      Order.where(
        tenant_id: @point.id,
        customer_id: @customer.id,
        status: Shop::SubscriptionOfferEligibility::COMPLETED_STATUSES
      ).where("created_at > ?", time).count
    end

    def subscribed?
      Subscription.for_customer(@customer.id).where(status: %i[active past_due]).exists?
    end

    def unread?(state)
      return false if state.nil? || state.purchased?

      state.unread_since.present?
    end

    def completed_orders_count
      @completed_orders_count ||= Shop::SubscriptionOfferEligibility.new(@customer, @point).completed_orders_count
    end
  end
end
