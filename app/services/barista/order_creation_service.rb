# frozen_string_literal: true

module Barista
  # Создаёт заказ баристы: валидирует корзину, считает суммы,
  # создаёт Order + OrderItems + Payment + OrderStatusLog в одной транзакции.
  # В1: только при открытой CashShift (@shift.open?) — см. docs/operations/milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md.
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
      unless @shift&.open?
        raise OrderCreationError, "Смена не открыта"
      end

      validated_items = CartValidationService.new(@cart_items, tenant_id: @tenant_id).call!

      total_amount    = validated_items.sum { |i| i[:total_price] }
      discount_amount, promo_record = promo_discount_and_record(total_amount)
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

        begin
          Inventory::OrderRecipeDeduction.call!(order: order.reload)
        rescue Inventory::OrderRecipeDeduction::Error => e
          # TASK_93-A: склад не блокирует создание accepted-заказа (deduction soft-fail + audit).
          Rails.logger.error("[Barista::OrderCreationService] stock soft-fail: #{e.message}")
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

        order.reload
        if order.order_number.blank?
          raise OrderCreationError, "order_number не назначен (триггер generate_order_number)"
        end

        if promo_record && discount_amount.positive?
          promo_record.with_lock do
            if promo_record.max_uses > 0 && promo_record.used_count >= promo_record.max_uses
              raise OrderCreationError, "Промокод исчерпан"
            end
            promo_record.increment_usage!
          end
        end

        order
      end
    end

    private

    def promo_discount_and_record(total)
      return [ 0, nil ] unless @promo_code.present?

      promo = PromoCode.find_by(code: @promo_code, tenant_id: @tenant_id)
      return [ 0, nil ] unless promo&.active?

      return [ 0, nil ] if promo.valid_from > Time.current || promo.valid_to < Time.current
      return [ 0, nil ] if promo.max_uses > 0 && promo.used_count >= promo.max_uses

      discount = (total * promo.discount_percentage / 100).round(2)
      return [ 0, nil ] unless discount.positive?

      [ discount, promo ]
    end
  end
end
