# frozen_string_literal: true

module Shop
  class OrderCreator
    class Error < StandardError; end

    def initialize(session, tenant:, shop_customer_session_key: :shop_customer_id)
      @session = session
      @tenant = tenant
      @shop_customer_session_key = shop_customer_session_key
    end

    def call!(params)
      cart_data = Shop::CartService.new(@session, @tenant.id).json_lines
      raise Error, "Корзина пуста" if cart_data[:items].empty?

      subtotal = BigDecimal(cart_data[:total].to_s)
      discount = promo_discount(subtotal, params)
      total = (subtotal - discount).round(2)
      raise Error, "Сумма заказа некорректна" if total < 0

      customer = find_or_create_customer!(params)

      # BUG-016 FIX: Наличные оплачиваются сразу (бариста принимает деньги),
      # безналичные (card, sbp, apple_pay, google_pay) ждут подтверждения от платёжного провайдера.
      payment_method   = map_payment_method(params[:payment_method])
      cash_payment     = payment_method == :cash
      order_status     = cash_payment ? :accepted : :pending_payment
      payment_status   = cash_payment ? :succeeded : :pending
      paid_at          = cash_payment ? Time.current : nil

      order = nil
      ActiveRecord::Base.transaction do
        order = Order.create!(
          tenant_id: @tenant.id,
          customer_id: customer.id,
          customer_name: customer.full_name.presence || params[:name].presence || "Гость",
          order_number: "",
          source: :mobile,
          status: order_status,
          total_amount: subtotal,
          discount_amount: discount,
          final_amount: total,
          promo_code_id: nil
        )

        cart_data[:items].each do |line|
          product = Product.find(line[:product_id])
          # BUG-020 FIX: Перепроверяем доступность товара внутри транзакции перед созданием заказа.
          raise Error, "Товар '#{product.name}' стал недоступен. Обновите корзину." unless shop_available_for_order?(product)
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
          status_to: order_status,
          source: :customer,
          comment: cash_payment ? "Наличная оплата на витрине /shop" : "Ожидание подтверждения оплаты #{payment_method}"
        )

        Payment.create!(
          order_id: order.id,
          tenant_id: @tenant.id,
          amount: total,
          method: payment_method,
          provider: "shop",
          status: payment_status,
          paid_at: paid_at
        )

        @session[Shop::CartService::SESSION_KEY] = []
        @session[@shop_customer_session_key] = customer.id
      end

      order
    end

    private

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

    # BUG-020 FIX: Проверка доступности товара с блокировкой внутри транзакции.
    def shop_available_for_order?(product)
      return false unless product.is_active?

      ProductTenantSetting
        .lock("FOR SHARE")
        .exists?(product_id: product.id, tenant_id: @tenant.id, is_enabled: true, is_sold_out: false)
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
