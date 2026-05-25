# frozen_string_literal: true

module Inventory
  # Block F: списание ингредиентов по product_recipes (+ modifier_option_recipes) при продаже.
  # Вызывается после создания order_items, когда заказ сразу accepted (INSERT).
  # UPDATE pending→accepted покрывает DB-триггер auto_deduct_ingredients_on_order_accept.
  class OrderRecipeDeduction
    class Error < StandardError; end

    def self.call!(order:)
      new(order: order).call!
    end

    def initialize(order:)
      @order = order
    end

    def call!
      return @order unless @order.status == "accepted"

      items = @order.order_items.to_a
      return @order if items.empty?

      totals = ingredient_totals(items)
      return @order if totals.empty?

      tenant_id = @order.tenant_id
      ActiveRecord::Base.transaction do
        totals.each do |ingredient_id, qty_needed|
          next if qty_needed <= 0

          stock = IngredientTenantStock.lock.find_or_create_by!(
            tenant_id: tenant_id,
            ingredient_id: ingredient_id
          ) do |row|
            row.qty = 0
            row.min_qty = 0
          end

          stock.update!(
            qty: stock.qty - qty_needed,
            last_updated_at: Time.current
          )
        end
      end

      @order
    end

    private

    def ingredient_totals(items)
      product_ids = items.map(&:product_id).uniq
      recipes_by_product = ProductRecipe.where(product_id: product_ids).group_by(&:product_id)

      option_ids = items.flat_map { |item| selected_modifier_ids(item.modifier_options) }.uniq
      option_recipes = ModifierOptionRecipe.where(option_id: option_ids).group_by(&:option_id)

      totals = Hash.new(0.to_d)
      items.each do |item|
        recipes_by_product[item.product_id].to_a.each do |recipe|
          qty_needed = recipe.qty_per_serving * item.quantity
          selected_modifier_ids(item.modifier_options).each do |opt_id|
            option_recipes[opt_id].to_a.each do |opt_recipe|
              next unless opt_recipe.ingredient_id == recipe.ingredient_id

              qty_needed += opt_recipe.qty_change * item.quantity
            end
          end
          totals[recipe.ingredient_id] += qty_needed
        end
      end
      totals
    end

    def selected_modifier_ids(modifier_options)
      return [] unless modifier_options.is_a?(Hash)

      Array(modifier_options["selected_modifiers"] || modifier_options[:selected_modifiers]).filter_map do |mod|
        id = mod.is_a?(Hash) ? (mod["id"] || mod[:id]) : nil
        id.presence
      end
    end
  end
end
