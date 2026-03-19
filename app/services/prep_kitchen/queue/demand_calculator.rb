module PrepKitchen
  module Queue
    class DemandCalculator
      def self.call(orders:)
        new(orders: orders).call
      end

      def initialize(orders:)
        @orders = orders
      end

      def call
        order_items = @orders.flat_map(&:order_items)
        product_ids = order_items.map(&:product_id).uniq

        recipes_by_product = ProductRecipe.where(product_id: product_ids).group_by(&:product_id)
        option_ids = order_items.flat_map { |item| modifier_option_ids(item.modifier_options) }.uniq
        option_recipes = ModifierOptionRecipe.where(option_id: option_ids).group_by(&:option_id)

        ingredient_totals = Hash.new(0.to_d)
        product_totals = Hash.new(0)

        order_items.each do |item|
          product_totals[item.product_name] += item.quantity
          recipes_by_product[item.product_id].to_a.each do |recipe|
            qty_needed = recipe.qty_per_serving * item.quantity
            modifier_option_ids(item.modifier_options).each do |opt_id|
              option_recipes[opt_id].to_a.each do |opt_recipe|
                next unless opt_recipe.ingredient_id == recipe.ingredient_id

                qty_needed += opt_recipe.qty_change * item.quantity
              end
            end
            ingredient_totals[recipe.ingredient_id] += qty_needed
          end
        end

        ingredient_names = Ingredient.where(id: ingredient_totals.keys).pluck(:id, :name, :unit).to_h do |id, name, unit|
          [id, { name: name, unit: unit }]
        end

        ingredient_demand = ingredient_totals.map do |ingredient_id, qty|
          meta = ingredient_names[ingredient_id] || { name: "ingredient##{ingredient_id}", unit: "-" }
          { ingredient_id: ingredient_id, name: meta[:name], unit: meta[:unit], qty: qty }
        end.sort_by { |row| -row[:qty].to_f }

        { product_demand: product_totals.sort_by { |_name, qty| -qty }, ingredient_demand: ingredient_demand }
      end

      private

      def modifier_option_ids(modifier_options)
        return [] unless modifier_options.is_a?(Hash)

        modifier_options.values.filter_map { |value| value.presence }
      end
    end
  end
end
