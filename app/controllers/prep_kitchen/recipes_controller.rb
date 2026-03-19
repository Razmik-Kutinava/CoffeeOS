module PrepKitchen
  class RecipesController < BaseController
    def index
      @products = Product.includes(:category).order(:sort_order, :name)
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
      @products = @products.where(id: params[:product_id]) if params[:product_id].present?
      if params[:q].present?
        query = "%#{params[:q].strip}%"
        @products = @products.where("products.name ILIKE ?", query)
      end

      @products = @products.limit(200)
      product_ids = @products.map(&:id)
      @recipes_by_product = ProductRecipe.includes(:ingredient).where(product_id: product_ids).group_by(&:product_id)
      @modifier_effects_by_product = ModifierOptionRecipe
                                     .joins(option: :group)
                                     .includes(:ingredient, option: :group)
                                     .where(product_modifier_groups: { product_id: product_ids })
                                     .group_by { |row| row.option.group.product_id }
    end
  end
end
