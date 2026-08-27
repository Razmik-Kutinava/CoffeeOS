# frozen_string_literal: true

module Shop
  # POST widget_init: one-click Charge по RebillId или Init(Widget) без карты.
  class WidgetPaymentInitiator
    class Error < StandardError; end

    def self.call(order:, return_base_url:, notification_url:, rebill_id: nil, extra_customer_ids: [], adapter: nil)
      new(
        order: order,
        return_base_url: return_base_url,
        notification_url: notification_url,
        rebill_id: rebill_id,
        extra_customer_ids: extra_customer_ids,
        adapter: adapter
      ).call
    end

    def initialize(order:, return_base_url:, notification_url:, rebill_id: nil, extra_customer_ids: [], adapter: nil)
      @order = order
      @return_base_url = return_base_url
      @notification_url = notification_url
      @rebill_id = rebill_id.to_s.presence
      @extra_customer_ids = Array(extra_customer_ids).compact
      @adapter = adapter || Payments::TbankAdapter.new
    end

    def call
      payment = @order.payments.order(created_at: :desc).first
      raise Error, "Payment missing" unless payment

      rebill_id = @rebill_id || resolve_rebill_id

      if payment.provider_payment_id.present?
        return charge_existing!(payment, rebill_id) if payment.pending? && rebill_id.present?

        return { provider_payment_id: payment.provider_payment_id.to_s }
      end

      if rebill_id.present?
        charge_with_rebill!(payment, rebill_id)
      else
        init_widget_only!(payment)
      end
    end

    private

    def resolve_rebill_id
      customer_ids = [ @order.customer_id, *@extra_customer_ids ].compact.uniq
      customer_ids.each do |cid|
        token = MobilePaymentMethod.primary_for(cid)&.rebill_id
        return token if token.present?
      end
      nil
    end

    # Как Shop::RecurrentOrderCreator: Init → Charge, проверка Success, settle CONFIRMED.
    # Init PaymentId сохраняем сразу — иначе при падении Charge в БД остаётся pid=nil.
    def charge_with_rebill!(payment, rebill_id)
      receipt = Payments::TbankReceiptBuilder.for_order!(@order)
      init_result = @adapter.init_payment(
        order: @order,
        return_base_url: @return_base_url,
        notification_url: @notification_url,
        customer_key: @order.customer_id&.to_s,
        recurrent: false,
        receipt: receipt
      )
      pid = init_result[:provider_payment_id].to_s
      payment.update_columns(provider: "tbank", provider_payment_id: pid)

      charge_response = @adapter.charge(payment_id: pid, rebill_id: rebill_id)
      result = Payments::TbankPaymentResult.new(charge_response)
      unless result.success?
        # #46: не оставляем pid — иначе retry → charge_existing! → Error 119 (лимит авторизаций).
        clear_provider_payment_id!(payment)
        raise Payments::TbankAdapter::ApiError.new(
          error_code: result.error_code,
          message: result.message
        )
      end

      if result.confirmed?
        settle_confirmed!(payment, charge_response, pid)
      elsif result.three_ds?
        Rails.logger.info("[WidgetPaymentInitiator] 3DS required order=#{@order.id}")
      else
        Payments::TbankPaymentSync.sync_order!(order: @order.reload)
      end

      { provider_payment_id: pid, charge_response: charge_response }
    end

    def init_widget_only!(payment)
      result = Payments::TbankInlineInit.call(
        order: @order,
        return_base_url: @return_base_url,
        notification_url: @notification_url,
        customer_key: @order.customer_id&.to_s,
        connection_type: "Widget",
        adapter: @adapter
      )
      payment.update_columns(provider: "tbank", provider_payment_id: result[:provider_payment_id])
      result
    end

    def charge_existing!(payment, rebill_id)
      charge_response = @adapter.charge(
        payment_id: payment.provider_payment_id,
        rebill_id: rebill_id
      )
      result = Payments::TbankPaymentResult.new(charge_response)
      unless result.success?
        # #46: REJECTED Charge на том же PaymentId нельзя ретраить.
        clear_provider_payment_id!(payment)
        raise Payments::TbankAdapter::ApiError.new(
          error_code: result.error_code,
          message: result.message
        )
      end

      pid = charge_response["PaymentId"].to_s.presence || payment.provider_payment_id.to_s
      payment.update_columns(provider: "tbank", provider_payment_id: pid)

      if result.confirmed?
        settle_confirmed!(payment, charge_response, pid)
      else
        Payments::TbankPaymentSync.sync_order!(order: @order.reload)
      end

      { provider_payment_id: pid }
    end

    def clear_provider_payment_id!(payment)
      payment.update_columns(provider_payment_id: nil)
    end

    def settle_confirmed!(payment, raw, pid)
      Callbacks::PaymentStatusUpdater.new(
        payment: payment,
        new_status: "succeeded",
        provider_data: raw.except("Token", "Password"),
        provider_payment_id: pid,
        note: "Widget Charge CONFIRMED"
      ).call!
      @order.reload
    end
  end
end
