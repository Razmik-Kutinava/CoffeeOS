# frozen_string_literal: true

module Shop
  # Сливает группы с одинаковым name (разный id в БД после правок УК) в одну группу для shop API.
  class ModifierGroupsPresenter
    Row = Struct.new(:id, :name, :is_required, :sort_order, :modifiers, keyword_init: true)

    def self.deduplicated_rows(product)
      new(product).deduplicated_rows
    end

    def initialize(product)
      @product = product
    end

    def deduplicated_rows
      rows = []
      by_key = {}

      loaded_groups.each do |group|
        key = group.name.to_s.strip.downcase
        if (existing = by_key[key])
          merge_modifiers!(existing, group)
        else
          row = row_from_group(group)
          by_key[key] = row
          rows << row
        end
      end

      rows
    end

    private

    def row_from_group(group)
      Row.new(
        id: group.id,
        name: group.name,
        is_required: group.is_required,
        sort_order: group.sort_order,
        modifiers: active_options(group)
      )
    end

    def merge_modifiers!(row, group)
      seen = row.modifiers.map { |m| normalize_name(m.name) }.to_set
      active_options(group).each do |opt|
        key = normalize_name(opt.name)
        next if seen.include?(key)

        row.modifiers << opt
        seen << key
      end
    end

    def loaded_groups
      assoc = @product.association(:product_modifier_groups)
      records = if assoc.loaded?
        assoc.target
      else
        @product.product_modifier_groups.includes(:product_modifier_options).to_a
      end
      records.sort_by { |g| g.sort_order.to_i }
    end

    # Не .active.ordered — scope на preload бьёт SELECT на каждую группу (Sentry RUBY-19).
    def active_options(group)
      opts = group.product_modifier_options
      records = opts.loaded? ? opts.target : opts.to_a
      records.select(&:is_active).sort_by { |o| o.sort_order.to_i }
    end

    def normalize_name(name)
      name.to_s.strip.downcase
    end
  end
end
