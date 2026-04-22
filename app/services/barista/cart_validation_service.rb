# frozen_string_literal: true

module Barista
  # Проверяет корзину: товары существуют, доступны, не распроданы.
  # Возвращает список позиций с ценами либо бросает CartValidationError.
  class CartValidationService
    class CartValidationError < StandardError; end

    def initialize(cart_items, tenant_id:)
      @cart_items = cart_items
      @tenant_id  = tenant_id
    end

    # Возвращает Array<Hash> с ключами: product, quantity, price, total_price
    def call!
      raise CartValidationError, "Корзина пуста" if @cart_items.blank?

      product_ids  = @cart_items.map { |i| (i[:product_id] || i["product_id"]).to_s }.reject(&:blank?)
      products_map = Product.where(id: product_ids).index_by { |p| p.id.to_s }
      settings_map = ProductTenantSetting
        .where(product_id: product_ids, tenant_id: @tenant_id)
        .index_by { |s| s.product_id.to_s }

      @cart_items.map do |item|
        product_id = (item[:product_id] || item["product_id"]).to_s
        quantity   = (item[:quantity]   || item["quantity"]   || 1).to_i

        product = products_map[product_id]
        raise ActiveRecord::RecordNotFound, "Товар ##{product_id} не найден" unless product

        setting = settings_map[product_id]
        unless setting&.is_enabled && !setting.is_sold_out
          raise CartValidationError, "Продукт недоступен или закончился"
        end

        { product: product, quantity: quantity, price: setting.price, total_price: setting.price * quantity }
      end
    end
  end
end
