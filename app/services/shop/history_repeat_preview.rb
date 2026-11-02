# frozen_string_literal: true

module Shop
  # TASK_121: текущие цены и наличие позиций исторического заказа в точке — без сессии гостя.
  class HistoryRepeatPreview
    def initialize(order:, tenant_id:)
      @order = order
      @tenant_id = tenant_id
    end

    def call
      items = @order.order_items.map { |item| preview_line(item) }
      {
        order_id: @order.id,
        items: items,
        total: items.sum { |line| line[:unavailable] ? 0.0 : line[:line_total].to_f },
        previous_total: @order.final_amount.to_f,
        previous_discount: @order.discount_amount.to_f
      }
    end

    private

    def preview_line(item)
      base = {
        product_id: item.product_id,
        product_name: item.product_name,
        quantity: item.quantity,
        price: item.unit_price.to_f
      }

      if item.product_id.blank?
        return base.merge(unavailable: true, unit_total: nil, line_total: nil)
      end

      mods = item.modifier_options&.dig("selected_modifiers") || []
      if inactive_modifier?(mods)
        return base.merge(unavailable: true, unit_total: nil, line_total: nil)
      end

      session = {}
      cart = CartService.new(session, @tenant_id)
      cart.add!(
        product_id: item.product_id,
        quantity: item.quantity,
        selected_modifiers: mods
      )
      line = cart.json_lines[:items].first
      base.merge(
        unit_total: line[:unit_total],
        line_total: line[:line_total],
        unavailable: false
      )
    rescue ActiveRecord::RecordNotFound, CartService::OverflowError
      base.merge(unavailable: true, unit_total: nil, line_total: nil)
    end

    def inactive_modifier?(mods)
      ids = Array(mods).filter_map { |m| (m["id"] || m[:id]).presence }
      return false if ids.empty?

      active = ProductModifierOption.where(id: ids, is_active: true).pluck(:id).map(&:to_s)
      ids.any? { |id| !active.include?(id.to_s) }
    end
  end
end
