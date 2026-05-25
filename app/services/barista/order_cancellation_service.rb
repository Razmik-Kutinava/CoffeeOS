# frozen_string_literal: true

module Barista
  # Отмена заказа баристой: статус, лог, аудит; при preparing + ингредиенты не использованы — возврат на склад.
  class OrderCancellationService
    class OrderCancellationError < StandardError; end

    def initialize(order:, actor:, tenant_id:, user_id:, reason: nil, reason_code: nil, ingredients_used: nil, request_id: nil)
      @order = order
      @actor = actor
      @tenant_id = tenant_id
      @user_id = user_id
      @reason = reason.to_s.strip
      @reason_code = reason_code
      @ingredients_used = ingredients_used
      @request_id = request_id
    end

    def call!
      raise OrderCancellationError, "Укажите причину отмены" if @reason.blank?

      old_status = @order.status

      ActiveRecord::Base.transaction do
        @order.update!(
          status: "cancelled",
          cancel_reason: @reason,
          cancel_reason_code: @reason_code,
          cancel_stage: old_status
        )

        OrderStatusLog.create!(
          order_id: @order.id,
          status_from: old_status,
          status_to: "cancelled",
          changed_by_id: @user_id,
          device_id: nil,
          source: "barista",
          comment: @reason
        )

        AdminAuditLog.log(
          action: "order_cancelled",
          actor: @actor,
          entity: @order,
          tenant_id: @tenant_id,
          details: {
            order_number: @order.order_number,
            cancel_reason: @order.cancel_reason,
            cancel_stage: old_status,
            final_amount: @order.final_amount
          },
          request_id: @request_id
        )

        restore_stock_if_needed!(old_status: old_status)
      end

      @order.reload
    end

    private

    def restore_stock_if_needed!(old_status:)
      return unless old_status == "preparing" && @ingredients_used.to_s == "false"

      movement = StockMovement.create!(
        tenant_id: @tenant_id,
        movement_type: :return,
        status: :confirmed,
        created_by_id: @user_id,
        confirmed_by_id: @user_id,
        confirmed_at: Time.current,
        reference_id: @order.id,
        note: "Возврат при отмене заказа ##{@order.order_number} (ингредиенты не использованы)"
      )

      product_ids = @order.order_items.pluck(:product_id)
      recipes = ProductRecipe.where(product_id: product_ids).includes(:ingredient)
      recipes_by_product = recipes.group_by(&:product_id)

      @order.order_items.each do |item|
        (recipes_by_product[item.product_id] || []).each do |recipe|
          qty_to_restore = recipe.qty_per_serving * item.quantity
          movement.stock_movement_items.create!(
            ingredient_id: recipe.ingredient_id,
            qty_change: qty_to_restore
          )
          restore_ingredient_qty!(recipe.ingredient_id, qty_to_restore)
        end
      end
    end

    def restore_ingredient_qty!(ingredient_id, qty_to_restore)
      stock = IngredientTenantStock.lock.find_or_create_by!(
        tenant_id: @tenant_id,
        ingredient_id: ingredient_id
      ) do |new_stock|
        new_stock.qty = 0
        new_stock.min_qty = 0
      end

      stock.update!(qty: stock.qty + qty_to_restore, last_updated_at: Time.current)
    end
  end
end
