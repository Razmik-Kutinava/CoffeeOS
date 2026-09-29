# frozen_string_literal: true

module Subscriptions
  # Идемпотентное завершение оплаты подписки (sync PurchaseService или T-Bank webhook).
  # Не вызывает PaymentStatusUpdater → accepted (табло баристы).
  class PaymentFulfillment
    class Error < StandardError; end

    def self.call(payment:)
      new(payment: payment).call
    end

    def initialize(payment:)
      @payment = payment
    end

    def call
      data = @payment.provider_data
      return nil unless data.is_a?(Hash)
      return nil unless ActiveModel::Type::Boolean.new.cast(data["subscription_intent"])

      existing = Subscription.find_by(payment_id: @payment.id)
      return existing if existing

      plan_id = data["subscription_plan_id"].presence
      raise Error, "subscription_plan_id missing" if plan_id.blank?

      plan = SubscriptionPlan.find(plan_id)
      customer_id = @payment.order.customer_id
      raise Error, "order without customer" if customer_id.blank?

      pm_id = resolve_payment_method_id(data)
      auto_renew = ActiveModel::Type::Boolean.new.cast(data.fetch("auto_renew", true))
      attribution = resolve_attribution(data, customer_id)

      subscription = Subscription.new(
        customer_id: customer_id,
        plan_id: plan.id,
        purchase_point_id: @payment.order.tenant_id,
        payment_method_id: pm_id,
        payment_id: @payment.id,
        auto_renew: auto_renew,
        status: :active,
        **attribution
      )
      subscription.start_period_from_plan!(plan)
      subscription.save!
      Subscriptions::OfferPresentationService.mark_purchased!(customer_id: customer_id)
      log_purchase(subscription)
      subscription
    end

    private

    # TASK_96: UTM из покупки приоритетнее; иначе — последний offer_opened/push_opened гостя.
    def resolve_attribution(data, customer_id)
      explicit = {
        utm_campaign: data["utm_campaign"].presence,
        utm_content: data["utm_content"].presence,
        offer_channel: data["offer_channel"].presence
      }
      return explicit if explicit.values.any?

      last_open = MarketingEvent.where(customer_id: customer_id, event_type: MarketingEvent::OPEN_EVENT_TYPES)
        .order(occurred_at: :desc).first
      return explicit unless last_open

      { utm_campaign: last_open.utm_campaign, utm_content: last_open.utm_content, offer_channel: last_open.channel }
    rescue StandardError => e
      Rails.logger.warn("[Subscriptions::PaymentFulfillment] attribution: #{e.class}: #{e.message}")
      explicit
    end

    def log_purchase(subscription)
      Subscriptions::MarketingEventLogger.log(
        event_type: :subscription_purchased,
        customer_id: subscription.customer_id,
        point_id: subscription.purchase_point_id,
        channel: subscription.offer_channel,
        utm_campaign: subscription.utm_campaign,
        utm_content: subscription.utm_content,
        metadata: { "subscription_id" => subscription.id, "payment_id" => @payment.id }
      )
    end

    # Патч 1 / 5a: не подставлять фиктивный payment_method_id; только реальный id из data / SavedCard.
    def resolve_payment_method_id(data)
      explicit = data["subscription_payment_method_id"].presence
      return explicit if explicit

      # Card bind from same payment (SavedCardStore may have written RebillId → MobilePaymentMethod).
      rebill = data["RebillId"].presence || data["rebill_id"].presence
      if rebill.present?
        pm = MobilePaymentMethod.find_by(customer_id: @payment.order.customer_id, card_token: rebill, is_active: true)
        return pm.id if pm
      end

      nil
    end
  end
end
