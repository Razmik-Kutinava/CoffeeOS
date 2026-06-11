# frozen_string_literal: true

module Shop
  class ModifierSelection
    def self.build(product:, selected_modifiers:)
      selected = normalize_modifiers(selected_modifiers)
      selected_ids = selected.filter_map { |m| m["id"].presence&.to_s }.to_set
      removed = product_modifier_options(product)
        .reject { |opt| selected_ids.include?(opt.id.to_s) }
        .map { |opt| option_hash(opt) }

      { selected_modifiers: selected, removed_modifiers: removed }
    end

    def self.normalize_modifiers(mods)
      Array(mods).map do |m|
        h = ActiveSupport::HashWithIndifferentAccess.new(m.respond_to?(:to_unsafe_h) ? m.to_unsafe_h : m)
        {
          "id" => h[:id],
          "name" => h[:name],
          "price" => BigDecimal(h[:price].to_s).to_f
        }
      end
    end

    def self.product_modifier_options(product)
      ProductModifierOption
        .joins(:group)
        .merge(ProductModifierGroup.ordered)
        .where(product_modifier_groups: { product_id: product.id })
        .where(is_active: true)
        .order("product_modifier_groups.sort_order ASC", "product_modifier_options.sort_order ASC")
    end

    def self.option_hash(opt)
      {
        "id" => opt.id,
        "name" => opt.name,
        "price" => opt.price_delta.to_f
      }
    end

    private_class_method :normalize_modifiers, :product_modifier_options, :option_hash
  end
end
