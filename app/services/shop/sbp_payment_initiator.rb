# frozen_string_literal: true

module Shop
  # SBP deep link: Init (Receipt 54-ФЗ) → GetQr PAYMENT_LINK → { payment_url }.
  # Работает по уже созданному заказу pending_payment (не создаёт Order).
  class SbpPaymentInitiator
    class Error < StandardError
      attr_reader :http_status, :error_code

      def initialize(message, http_status: :unprocessable_entity, error_code: nil)
        @http_status = http_status
        @error_code = error_code.to_s.presence
        super(message)
      end
    end

    def initialize(tenant:, request: nil, adapter: nil, qr_fetcher: nil)
      @tenant = tenant
      @request = request
      @adapter = adapter || Payments::TbankAdapter.new
      @qr_fetcher = qr_fetcher || Payments::TbankQrFetcher
    end

    def call!(order_id:, return_base_url: nil, notification_url: nil, save_sbp_account: false)
      order = find_pending_order!(order_id)
      @save_sbp_account = ActiveModel::Type::Boolean.new.cast(save_sbp_account)

      if Shop::PaymentConfig.simulate?
        return simulate_result(order)
      end

      live_result(
        order,
        return_base_url: return_base_url,
        notification_url: notification_url
      )
    end

    private

    def find_pending_order!(order_id)
      order = Order.includes(:order_items, :payments)
        .find_by(id: order_id, tenant_id: @tenant.id)
      raise Error.new("Заказ не найден", http_status: :not_found) unless order
      unless order.pending_payment?
        raise Error.new("Заказ недоступен для оплаты СБП (нужен pending_payment)", http_status: :unprocessable_entity)
      end
      order
    end

    def simulate_result(order)
      payment = order.payments.order(created_at: :desc).first
      apply_growth_pricing!(order, payment) if payment
      mark_save_sbp_account!(order)
      {
        payment_url: "https://qr.nspk.ru/SIMULATE-#{order.id.to_s.delete("-")[0, 12]}",
        order_id: order.id,
        provider_payment_id: nil
      }
    end

    def live_result(order, return_base_url:, notification_url:)
      base = return_base_url.presence || ENV.fetch("TBANK_RETURN_URL") { @request&.base_url.to_s }
      notify = notification_url.presence || "#{base}/callbacks/tbank"
      raise Error.new("Не задан return_base_url / TBANK_RETURN_URL", http_status: :internal_server_error) if base.blank?

      payment = order.payments.order(created_at: :desc).first
      raise Error.new("У заказа нет платежа", http_status: :unprocessable_entity) unless payment

      begin
        apply_growth_pricing!(order, payment)

        # #72: контакт покупателя в Receipt (Email > Phone) из MobileCustomer.
        receipt = Payments::TbankReceiptBuilder.for_order!(order)
        init_kwargs = {
          order: order,
          return_base_url: base,
          notification_url: notify,
          customer_key: order.customer_id&.to_s,
          recurrent: @save_sbp_account,
          receipt: receipt
        }
        init_kwargs[:data] = { "QR" => "true" } if @save_sbp_account

        init = @adapter.init_payment(**init_kwargs)

        payment.update_columns(
          provider: "tbank",
          provider_payment_id: init[:provider_payment_id]
        )
        mark_save_sbp_account!(order)

        qr = @qr_fetcher.call!(payment_id: init[:provider_payment_id], adapter: @adapter)
        {
          payment_url: qr[:payment_url],
          order_id: order.id,
          provider_payment_id: init[:provider_payment_id]
        }
      rescue Payments::TbankAdapter::ApiError => e
        Rails.logger.error("[SbpPaymentInitiator] #{e.class}: #{e.message}")
        raise Error.new(
          friendly_api_message(e),
          http_status: :unprocessable_entity,
          error_code: e.error_code
        )
      rescue Payments::TbankAdapter::Error, Payments::TbankQrFetcher::Error, Payments::TbankReceiptBuilder::Error => e
        Rails.logger.error("[SbpPaymentInitiator] #{e.class}: #{e.message}")
        raise Error.new(e.message, http_status: :internal_server_error)
      end
    end

    def mark_save_sbp_account!(order)
      return unless @save_sbp_account

      payment = order.payments.order(created_at: :desc).first
      return unless payment

      data = payment.provider_data.is_a?(Hash) ? payment.provider_data.deep_dup : {}
      data["save_sbp_account"] = true
      payment.update_columns(provider_data: data)
    end

    # #75: промо 11₽ на SBP bind — apply at init (save_sbp_account приходит сюда, не в POST /orders).
    def apply_growth_pricing!(order, payment)
      return unless @save_sbp_account

      data = payment.provider_data.is_a?(Hash) ? payment.provider_data : {}
      return if ActiveModel::Type::Boolean.new.cast(data["growth_promo_intent"])

      customer = order.customer || MobileCustomer.find_by(id: order.customer_id)
      return if customer.blank?

      priced = Payments::GrowthPromo.price!(
        subtotal: order.total_amount,
        discount: 0,
        tenant: @tenant,
        customer: customer,
        bind_requested: true
      )
      return unless priced[:growth_intent]

      order.update!(
        discount_amount: priced[:discount_amount],
        final_amount: priced[:final_amount]
      )
      merged = data.deep_dup
      merged["save_sbp_account"] = true
      merged["growth_promo_intent"] = true
      merged["cart_total_before_growth"] = priced[:cart_total_before].to_s
      payment.update!(amount: priced[:final_amount], provider_data: merged)
      order.reload
      payment.reload
    end

    def friendly_api_message(error)
      case error.error_code.to_s
      when "3001"
        "СБП сейчас недоступна для этой точки. Выберите оплату картой или попробуйте позже."
      else
        error.message
      end
    end
  end
end
