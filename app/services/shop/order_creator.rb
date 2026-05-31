# frozen_string_literal: true

module Shop
  class OrderCreator
    class Error < StandardError; end

    attr_reader :payment_url

    def initialize(session, tenant:, shop_customer_session_key: :shop_customer_id, request: nil)
      @session = session
      @tenant = tenant
      @shop_customer_session_key = shop_customer_session_key
      @request = request
    end

    def call!(params)
      cart_data = Shop::CartService.new(@session, @tenant.id).json_lines
      raise Error, "Корзина пуста" if cart_data[:items].empty?

      subtotal = BigDecimal(cart_data[:total].to_s)
      discount = promo_discount(subtotal, params)
      total = (subtotal - discount).round(2)
      raise Error, "Сумма заказа некорректна" if total < 0

      customer = find_or_create_customer!(params)

      payment_method = map_payment_method(params[:payment_method])
      flow = payment_flow(payment_method)

      order = nil
      payment = nil
      ActiveRecord::Base.transaction do
        # В1 гибрид смены: витрина/shop не привязана к CashShift (cash_shift_id остаётся NULL).
        # Barista POS — только через OrderCreationService с открытой сменой. См. docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md.
        order = Order.create!(
          tenant_id: @tenant.id,
          customer_id: customer.id,
          customer_name: customer.full_name.presence || params[:name].presence || "Гость",
          order_number: "",
          source: :mobile,
          status: flow[:order_status],
          total_amount: subtotal,
          discount_amount: discount,
          final_amount: total,
          promo_code_id: nil
        )

        product_ids = cart_data[:items].map { |line| line[:product_id] }.uniq
        products_by_id = Product.where(id: product_ids).index_by(&:id)
        available_product_ids = shop_available_product_ids(product_ids)

        cart_data[:items].each do |line|
          product = products_by_id[line[:product_id]]
          raise Error, "Товар не найден. Обновите корзину." unless product
          # BUG-020 FIX: Перепроверяем доступность товара внутри транзакции перед созданием заказа.
          unless available_product_ids.include?(product.id)
            raise Error, "Товар '#{product.name}' стал недоступен. Обновите корзину."
          end
          unit = BigDecimal(line[:unit_total].to_s)
          qty = line[:quantity].to_i
          OrderItem.create!(
            order_id: order.id,
            product_id: product.id,
            product_name: product.name,
            quantity: qty,
            unit_price: unit,
            total_price: unit * qty,
            modifier_options: { "selected_modifiers" => line[:selected_modifiers] }
          )
        end

        OrderStatusLog.create!(
          order_id: order.id,
          status_from: :pending_payment,
          status_to: flow[:order_status],
          source: :customer,
          comment: flow[:comment]
        )

        payment = Payment.create!(
          order_id: order.id,
          tenant_id: @tenant.id,
          amount: total,
          method: payment_method,
          provider: "shop",
          status: flow[:payment_status],
          paid_at: flow[:paid_at]
        )

        Inventory::OrderRecipeDeduction.call!(order: order.reload) if flow[:order_status] == :accepted

        @session[Shop::CartService::SESSION_KEY] = []
        @session[@shop_customer_session_key] = customer.id
      end

      begin
        init_gateway_payment!(order, payment) if flow[:order_status] == :pending_payment
      rescue Error => e
        void_pending_online_order!(order, payment)
        raise e
      end

      if order.accepted?
        Barista::OrderBoardBroadcaster.call(order: order.reload, old_status: "pending_payment")
      end

      order
    end

    private

    # В1: реального платёжного шлюза нет — имитация успешной оплаты (SHOP_SIMULATE_PAYMENT=1 по умолчанию).
    # В2: SHOP_SIMULATE_PAYMENT=0 — card/sbp ждут callback (Callbacks::PaymentStatusUpdater).
    def simulate_shop_payment?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_SIMULATE_PAYMENT", "1"))
    end

    def payment_flow(payment_method)
      if simulate_shop_payment?
        return {
          order_status: :accepted,
          payment_status: :succeeded,
          paid_at: Time.current,
          comment: "Имитация оплаты #{payment_method} на витрине /shop (реальный шлюз — веха 2)"
        }
      end

      cash_payment = payment_method == :cash
      {
        order_status: cash_payment ? :accepted : :pending_payment,
        payment_status: cash_payment ? :succeeded : :pending,
        paid_at: cash_payment ? Time.current : nil,
        comment: cash_payment ? "Наличная оплата на витрине /shop" : "Ожидание подтверждения оплаты #{payment_method}"
      }
    end

    def map_payment_method(raw)
      case raw.to_s.downcase
      when "cash" then :cash
      when "sbp" then :sbp
      when "apple_pay" then :apple_pay
      when "google_pay" then :google_pay
      else :card
      end
    end

    def promo_discount(subtotal, params)
      # BUG-004 FIX: Промокоды не реализованы — не применяем скидку.
      # Заглушка "10% на любой код" отключена во избежание финансовых потерь.
      0
    end

    # BUG-020 FIX: один запрос на все позиции корзины (FOR SHARE внутри транзакции OrderCreator).
    def shop_available_product_ids(product_ids)
      active_ids = Product.where(id: product_ids, is_active: true).pluck(:id)
      return [] if active_ids.empty?

      ProductTenantSetting
        .lock("FOR SHARE")
        .where(
          product_id: active_ids,
          tenant_id: @tenant.id,
          is_enabled: true,
          is_sold_out: false
        )
        .pluck(:product_id)
        .to_set
    end

    def shop_available_for_order?(product)
      return false unless product.is_active?

      ProductTenantSetting
        .lock("FOR SHARE")
        .exists?(product_id: product.id, tenant_id: @tenant.id, is_enabled: true, is_sold_out: false)
    end

    def void_pending_online_order!(order, payment)
      return unless order.pending_payment?

      order.update!(status: :cancelled)
      payment.update!(status: :failed) if payment.pending?
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Shop::OrderCreator] void_pending_online_order failed: #{e.message}")
    end

    def init_gateway_payment!(order, payment)
      return_base_url = ENV.fetch("TBANK_RETURN_URL", @request&.base_url.to_s)
      notification_url = "#{return_base_url}/callbacks/tbank"

      result = Payments::TbankAdapter.new.init_payment(
        order: order,
        return_base_url: return_base_url,
        notification_url: notification_url
      )

      payment.update_columns(
        provider: "tbank",
        provider_payment_id: result[:provider_payment_id]
      )

      @payment_url = result[:payment_url]
    rescue Payments::TbankAdapter::Error => e
      raise Error, "Не удалось инициировать оплату: #{e.message}"
    end

    def find_or_create_customer!(params)
      phone = params[:phone].to_s.gsub(/\s/, "")
      raise Error, "Укажите телефон" if phone.blank?

      customer = MobileCustomer.find_or_initialize_by(phone: phone)
      customer.first_name = params[:name].to_s.split(/\s+/).first.presence || "Гость"
      customer.last_name = params[:name].to_s.split(/\s+/)[1..]&.join(" ").presence
      customer.is_active = true
      customer.save!
      customer
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.join(", ")
    end
  end
end
