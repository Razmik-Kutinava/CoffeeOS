# frozen_string_literal: true

module Shop
  # Оплата в 1 клик: заказ + Init → Charge по UserCards.rebill_id (Шаг 4).
  class RecurrentOrderCreator
    class Error < StandardError; end

    attr_reader :provider_payment_id, :charge_result

    def initialize(session, tenant:, request: nil)
      @session = session
      @tenant = tenant
      @request = request
      @order_creator = OrderCreator.new(session, tenant: tenant, request: request)
    end

    def call!(params)
      raise Error, "Рекуррентная оплата недоступна в режиме имитации" if simulate_shop_payment?

      card = find_saved_card!(params)
      customer = find_customer!(params)

      unless card.customer_id.to_s == customer.id.to_s
        raise Error, "Карта не принадлежит этому гостю"
      end

      order_params = params.except(:saved_card_id, :card_id, :amount)
      order = @order_creator.call!(order_params.merge(payment_method: "card"), gateway: false)
      payment = order.payments.order(created_at: :desc).first
      raise Error, "Платёж не создан" unless payment&.pending?

      return_base_url = ENV.fetch("TBANK_RETURN_URL", @request&.base_url.to_s)
      notification_url = "#{return_base_url}/callbacks/tbank"

      charge_data = Payments::TbankAdapter.new.charge_recurrent(
        order: order,
        rebill_id: card.card_token,
        return_base_url: return_base_url,
        notification_url: notification_url,
        customer_key: customer.id.to_s
      )

      payment.update_columns(
        provider: "tbank",
        provider_payment_id: charge_data[:provider_payment_id]
      )
      @provider_payment_id = charge_data[:provider_payment_id]
      raw = charge_data[:charge_response] || {}
      @charge_result = Payments::TbankPaymentResult.new(raw)

      card.update!(last_used_at: Time.current, is_default: true)
      MobilePaymentMethod
        .where(customer_id: customer.id, payment_type: "card")
        .where.not(id: card.id)
        .update_all(is_default: false)

      if @charge_result.three_ds?
        Shop::PendingOrderSession.set!(@session, @tenant.id, order.id)
        return order
      end

      if @charge_result.confirmed?
        settle_confirmed!(order, payment, raw)
      else
        Payments::TbankPaymentSync.sync_order!(order: order.reload)
      end

      order.reload
    rescue Payments::TbankAdapter::ApiError => e
      raise TbankPaymentError.from_api(error_code: e.error_code, message: e.api_message)
    rescue Payments::TbankAdapter::Error => e
      raise OrderCreator::Error, e.message
    end

    private

    def settle_confirmed!(order, payment, raw)
      Callbacks::PaymentStatusUpdater.new(
        payment: payment,
        new_status: "succeeded",
        provider_data: raw.except("Token", "Password"),
        provider_payment_id: raw["PaymentId"].to_s.presence || payment.provider_payment_id,
        note: "Charge CONFIRMED"
      ).call!
      order.reload
      Shop::CartService.new(@session, @tenant.id).clear! if order.accepted?
      Shop::PendingOrderSession.clear!(@session, @tenant.id)
    end

    def simulate_shop_payment?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_SIMULATE_PAYMENT", "1"))
    end

    def find_saved_card!(params)
      card_id = params[:saved_card_id].presence || params[:card_id].presence
      raise Error, "Укажите card_id" if card_id.blank?

      card = MobilePaymentMethod.active_cards.find_by(id: card_id)
      raise Error, "Сохранённая карта не найдена" unless card

      card
    end

    def find_customer!(params)
      email = Shop::EmailVerificationSession.normalize(params[:email])
      raise Error, "Укажите email" if email.blank?

      verified = Shop::EmailVerification.verified_email(
        session: @session,
        tenant_id: @tenant.id,
        session_id: @request&.session&.id&.to_s,
        email: email
      )
      raise Error, "Подтвердите email кодом из письма" unless verified == email

      MobileCustomer.find_by!(email: email)
    rescue ActiveRecord::RecordNotFound
      raise Error, "Гость не найден"
    end
  end
end
