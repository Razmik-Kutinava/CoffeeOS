# frozen_string_literal: true

module Barista
  # Создаёт заказ баристы: валидирует корзину, считает суммы,
  # создаёт Order + OrderItems + Payment + OrderStatusLog в одной транзакции.
  class OrderCreationService
    class OrderCreationError < StandardError; end

    def initialize(cart_items:, payment_method:, customer_name:, promo_code:, shift:, tenant_id:, user_id:)
      @cart_items     = cart_items
      @payment_method = payment_method
      @customer_name  = customer_name
      @promo_code     = promo_code
      @shift          = shift
      @tenant_id      = tenant_id
      @user_id        = user_id
    end

    # Возвращает созданный Order либо бросает OrderCreationError / ActiveRecord::RecordNotFound
    def call!
      validated_items = CartValidationService.new(@cart_items, tenant_id: @tenant_id).call!

      total_amount    = validated_items.sum { |i| i[:total_price] }
      discount_amount = apply_promo(total_amount)
      final_amount    = total_amount - discount_amount

      ActiveRecord::Base.transaction do
        order = Order.create!(
          tenant_id:       @tenant_id,
          cash_shift_id:   @shift.id,
          order_number:    "", # генерируется триггером БД
          source:          "manual",
          customer_name:   @customer_name,
          status:          "accepted",
          total_amount:    total_amount,
          discount_amount: discount_amount,
          final_amount:    final_amount
        )

        validated_items.each do |item|
          OrderItem.create!(
            order_id:     order.id,
            product_id:   item[:product].id,
            product_name: item[:product].name,
            quantity:     item[:quantity],
            unit_price:   item[:price],
            total_price:  item[:total_price]
          )
        end

        Payment.create!(
          order_id:  order.id,
          tenant_id: @tenant_id,
          amount:    final_amount,
          method:    @payment_method,
          provider:  "manual",
          status:    "succeeded",
          paid_at:   Time.current
        )

        OrderStatusLog.create!(
          order_id:       order.id,
          status_from:    "pending_payment",
          status_to:      "accepted",
          changed_by_id:  @user_id,
          source:         "barista",
          comment:        "Заказ создан баристой"
        )

        order
      end
    end

    private

    def apply_promo(total)
      return 0 unless @promo_code.present?
      # TODO: валидация через модель PromoCode
      (total * 0.1).round(2)
    end
  end
end
