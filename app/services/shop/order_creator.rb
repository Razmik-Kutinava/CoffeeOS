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

      order = nil
      ActiveRecord::Base.transaction do
        order = Order.create!(
          tenant_id: @tenant.id,
          customer_id: customer.id,
          customer_name: customer.full_name.presence || params[:name].presence || "Гость",
          order_number: "",
          source: :mobile,
          status: :accepted,
          total_amount: subtotal,
          discount_amount: discount,
          final_amount: total,
          promo_code_id: nil
        )

        cart_data[:items].each do |line|
          product = Product.find(line[:product_id])
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
          status_to: :accepted,
          source: :customer,
          comment: "Заказ с витрины /shop"
        )

        Payment.create!(
          order_id: order.id,
          tenant_id: @tenant.id,
          amount: total,
          method: map_payment_method(params[:payment_method]),
          provider: "shop",
          status: :succeeded,
          paid_at: Time.current
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
      code = params[:promo_code].to_s.strip
      return 0 if code.blank?

      # Как в баристе: до появления модели PromoCode — тестовая скидка 10%
      (subtotal * 0.1).round(2)
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
