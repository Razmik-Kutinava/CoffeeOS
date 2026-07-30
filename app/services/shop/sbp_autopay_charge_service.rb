# frozen_string_literal: true

module Shop
  # #34 Zero-Click: Init → ChargeQr по AccountToken (сумма только из order в БД).
  class SbpAutopayChargeService
    class Error < StandardError
      attr_reader :http_status, :error_code, :fatal

      def initialize(message, http_status: :unprocessable_entity, error_code: nil, fatal: false)
        @http_status = http_status
        @error_code = error_code.to_s.presence
        @fatal = fatal
        super(message)
      end

      def fatal?
        @fatal
      end
    end

    def initialize(tenant:, request: nil, adapter: nil, autopay: nil)
      @tenant = tenant
      @request = request
      @adapter = adapter || Payments::TbankAdapter.new
      @autopay = autopay || Payments::TbankSbpAutopay.new(adapter: @adapter)
    end

    def call!(order_id:, customer_id: nil)
      order = find_pending_order!(order_id)
      token_row = find_account_token!(order, customer_id: customer_id)

      if Shop::PaymentConfig.simulate?
        return simulate_success(order)
      end

      live_charge!(order, token_row)
    end

    private

    def find_pending_order!(order_id)
      order = Order.includes(:order_items, :payments, :customer)
        .find_by(id: order_id, tenant_id: @tenant.id)
      raise Error.new("Заказ не найден", http_status: :not_found) unless order
      unless order.pending_payment?
        raise Error.new("Заказ недоступен для автоплатежа СБП", http_status: :unprocessable_entity)
      end
      order
    end

    def find_account_token!(order, customer_id:)
      cid = customer_id.presence || order.customer_id
      raise Error.new("Нет клиента для AccountToken", http_status: :unprocessable_entity) if cid.blank?

      row = MobilePaymentMethod
        .where(customer_id: cid, payment_type: "sbp", is_active: true)
        .order(is_default: :desc, last_used_at: :desc)
        .first
      raise Error.new("Нет привязанного счёта СБП", http_status: :unprocessable_entity) unless row

      row
    end

    def simulate_success(order)
      payment = order.payments.order(created_at: :desc).first
      payment&.update_columns(status: "succeeded", provider: "tbank")
      order.update_columns(status: "accepted") if order.respond_to?(:pending_payment?) && order.pending_payment?

      {
        order_id: order.id,
        status: "CONFIRMED",
        amount: order.final_amount
      }
    end

    def live_charge!(order, token_row)
      base = ENV.fetch("TBANK_RETURN_URL") { @request&.base_url.to_s }
      notify = "#{base}/callbacks/tbank"
      raise Error.new("Не задан return URL", http_status: :internal_server_error) if base.blank?

      receipt = Payments::TbankReceiptBuilder.call!(order: order, email: order.customer&.email)
      payment = order.payments.order(created_at: :desc).first
      raise Error.new("У заказа нет платежа", http_status: :unprocessable_entity) unless payment

      init = @adapter.init_payment(
        order: order,
        return_base_url: base,
        notification_url: notify,
        customer_key: order.customer_id&.to_s,
        recurrent: false,
        receipt: receipt,
        data: { "QR" => "true" }
      )
      payment.update_columns(provider: "tbank", provider_payment_id: init[:provider_payment_id])

      begin
        charged = @autopay.charge_qr(
          payment_id: init[:provider_payment_id],
          account_token: token_row.card_token
        )
      rescue Payments::TbankSbpAutopay::ChargeDeclined => e
        Payments::SbpAccountTokenStore.handle_charge_outcome!(
          customer_id: token_row.customer_id,
          account_token: token_row.card_token,
          fatal: e.fatal?
        )
        raise Error.new(e.message, error_code: e.error_code, fatal: e.fatal?)
      end

      token_row.update_columns(last_used_at: Time.current)
      {
        order_id: order.id,
        status: charged[:status].presence || "CONFIRMED",
        provider_payment_id: charged[:payment_id],
        amount: order.final_amount
      }
    rescue Payments::TbankAdapter::ApiError => e
      raise Error.new(e.message, error_code: e.error_code)
    rescue Payments::TbankAdapter::Error, Payments::TbankSbpAutopay::Error, Payments::TbankReceiptBuilder::Error => e
      raise Error.new(e.message, http_status: :internal_server_error, error_code: "NETWORK")
    end
  end
end
