# frozen_string_literal: true

module Shop
  # #77: server-side eligibility for subscription offer CTA on order ready.
  class SubscriptionOfferEligibility
    COMPLETED_STATUSES = %w[issued closed].freeze
    SIGNAL_ATTRIBUTES = %i[pwa_installed_at push_enabled_at email_collected_at].freeze

    def self.check(customer, point)
      new(customer, point).check
    end

    def initialize(customer, point)
      @customer = customer
      @point = point
    end

    def check
      return false unless @customer && @point

      setting = SubscriptionOfferSetting.for_point(@point.id)
      return false unless setting&.enabled?

      return false if completed_orders_count < setting.min_completed_orders
      return false if engagement_signals_count < setting.required_signals_count

      true
    end

    def completed_orders_count
      Order.where(
        tenant_id: @point.id,
        customer_id: @customer.id,
        status: COMPLETED_STATUSES
      ).count
    end

    def engagement_signals_count
      SIGNAL_ATTRIBUTES.count { |attr| @customer.public_send(attr).present? }
    end
  end
end
