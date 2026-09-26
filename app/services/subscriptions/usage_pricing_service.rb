# frozen_string_literal: true

module Subscriptions
  # Патч 1: лимит / over-limit по subscription_usage_events в окне 7 дней.
  # drinks_used_this_period не используется как источник истины.
  class UsagePricingService
    class Error < StandardError; end

    Result = Struct.new(
      :pricing_kind, :applied_price, :savings_amount, :usage_count, :in_limit, :event,
      keyword_init: true
    )

    def self.quote(subscription:, catalog_price:, at: Time.current)
      new(subscription: subscription, catalog_price: catalog_price, at: at).quote
    end

    def self.apply!(subscription:, order:, point:, catalog_price:, at: Time.current)
      new(
        subscription: subscription,
        catalog_price: catalog_price,
        at: at,
        order: order,
        point: point
      ).apply!
    end

    def initialize(subscription:, catalog_price:, at: Time.current, order: nil, point: nil)
      @subscription = subscription
      @catalog_price = BigDecimal(catalog_price.to_s)
      @at = at
      @order = order
      @point = point
    end

    def quote
      raise Error, "subscription missing" if @subscription.blank?
      raise Error, "subscription not active" unless @subscription.active?

      limit = @subscription.drink_limit_at_period_start.to_i
      used = @subscription.usage_count_in_rolling_window(at: @at)
      in_limit = used < limit

      if in_limit
        applied = BigDecimal(@subscription.plan.discount_price_per_drink.to_s)
        kind = "in_limit"
      else
        pct = @subscription.discount_percent_at_period_start.to_i
        discounted = (@catalog_price * (100 - pct) / 100).round(2)
        applied = round_down_to_ending_9(discounted)
        kind = "over_limit"
      end

      savings = [ @catalog_price - applied, BigDecimal("0") ].max

      Result.new(
        pricing_kind: kind,
        applied_price: applied,
        savings_amount: savings,
        usage_count: used,
        in_limit: in_limit,
        event: nil
      )
    end

    def apply!
      raise Error, "order required" if @order.blank?
      raise Error, "point required" if @point.blank?

      q = quote
      event = SubscriptionUsageEvent.create!(
        subscription_id: @subscription.id,
        order_id: @order.id,
        point_id: @point.id,
        applied_price: q.applied_price,
        savings_amount: q.savings_amount,
        pricing_kind: q.pricing_kind,
        created_at: @at,
        updated_at: @at
      )
      q.event = event
      q
    end

    private

    # Округление вниз до цены, оканчивающейся на 9 (канон ...9₽).
    def round_down_to_ending_9(amount)
      n = [ amount.to_d.floor, 0 ].max
      base = (n / 10) * 10
      candidate = base + 9
      result = candidate <= n ? candidate : base - 1
      BigDecimal([ result, 0 ].max.to_s)
    end
  end
end
