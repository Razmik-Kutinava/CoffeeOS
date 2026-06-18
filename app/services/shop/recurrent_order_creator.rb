# frozen_string_literal: true

module Shop
  # Оплата сохранённой картой (RebillId) без редиректа на форму банка — B1.12-R1.
  class RecurrentOrderCreator
    class Error < StandardError; end

    attr_reader :provider_payment_id

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

      order_params = params.except(:saved_card_id)
      order = @order_creator.call!(order_params.merge(payment_method: "card"), gateway: false)
      payment = order.payments.order(created_at: :desc).first
      raise Error, "Платёж не создан" unless payment&.pending?

      return_base_url = ENV.fetch("TBANK_RETURN_URL", @request&.base_url.to_s)
      notification_url = "#{return_base_url}/callbacks/tbank"

      result = Payments::TbankAdapter.new.charge_recurrent(
        order: order,
        rebill_id: card.card_token,
        return_base_url: return_base_url,
        notification_url: notification_url,
        customer_key: customer.id.to_s
      )

      payment.update_columns(
        provider: "tbank",
        provider_payment_id: result[:provider_payment_id]
      )
      @provider_payment_id = result[:provider_payment_id]

      card.update!(last_used_at: Time.current, is_default: true)
      MobilePaymentMethod
        .where(customer_id: customer.id, payment_type: "card")
        .where.not(id: card.id)
        .update_all(is_default: false)

      order
    rescue Payments::TbankAdapter::Error, Payments::TbankAdapter::ApiError => e
      raise OrderCreator::Error, map_charge_error(e)
    end

    private

    def simulate_shop_payment?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_SIMULATE_PAYMENT", "1"))
    end

    def find_saved_card!(params)
      card_id = params[:saved_card_id].presence
      raise Error, "Укажите saved_card_id" if card_id.blank?

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

    def map_charge_error(error)
      msg = error.message.to_s
      return "Недостаточно средств на карте" if msg.match?(/недостаточно|insufficient/i)
      return "Срок действия карты истёк" if msg.match?(/expir/i)
      return "Карта заблокирована" if msg.match?(/block/i)

      "Не удалось списать с сохранённой карты: #{msg}"
    end
  end
end
