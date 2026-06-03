# frozen_string_literal: true

# §2.2 демо: платные модификаторы на «Фильтр-кофе Бразилия» (+15 / +20 / +40 ₽).
class SetBrazilShopModifierPrices < ActiveRecord::Migration[8.1]
  DEMO_PRICES = [
    [ "Яблочный с корицей%", 15 ],
    [ "Пивной кордиал%", 20 ],
    [ "Мёд%", 40 ]
  ].freeze

  def up
    product = Product.find_by(slug: "filtr-kofe-braziliya")
    unless product
      say "filtr-kofe-braziliya не найден — пропуск"
      return
    end

    DEMO_PRICES.each do |pattern, price|
      updated = ProductModifierOption.joins(:group)
        .where(product_modifier_groups: { product_id: product.id })
        .where("product_modifier_options.name LIKE ?", pattern)
        .update_all(price_delta: price)
      say "  #{pattern} → #{price}₽ (#{updated} опций)"
    end
  end

  def down
    product = Product.find_by(slug: "filtr-kofe-braziliya")
    return unless product

    DEMO_PRICES.each do |pattern, _price|
      ProductModifierOption.joins(:group)
        .where(product_modifier_groups: { product_id: product.id })
        .where("product_modifier_options.name LIKE ?", pattern)
        .update_all(price_delta: 0)
    end
  end
end
