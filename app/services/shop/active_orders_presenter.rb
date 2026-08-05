# frozen_string_literal: true

module Shop
  # #36 — сериализация активных заказов для accordion + текстовый чек
  class ActiveOrdersPresenter
    def self.list(orders, tenant:)
      new(tenant: tenant).list(orders)
    end

    def initialize(tenant:)
      @tenant = tenant
    end

    def list(orders)
      Array(orders).map { |order| serialize(order) }
    end

    def serialize(order)
      {
        id: order.id,
        order_id: order.id,
        status: order.status,
        order_number: order.order_number,
        can_cancel: order.guest_can_cancel?,
        payment_settled: !order.pending_payment?,
        created_at: order.created_at&.iso8601,
        sales_point: sales_point_json,
        items: Array(order.order_items).map { |item| item_json(item) },
        subtotal: order.total_amount.to_f,
        discount: order.discount_amount.to_f,
        total_amount: order.final_amount.to_f
      }
    end

    private

    def sales_point_json
      {
        name: @tenant.name,
        address: @tenant.address,
        city: @tenant.city
      }
    end

    def item_json(item)
      {
        product_id: item.product_id,
        name: item.product_name,
        quantity: item.quantity,
        price: item.unit_price.to_f,
        modifiers: modifiers_json(item.modifier_options),
        discount: 0.0,
        line_total: item.total_price.to_f
      }
    end

    # Нормализация: selected_modifiers [{name, price}] → [{name, price}]; пусто → []
    def modifiers_json(raw)
      return [] if raw.blank?

      selected =
        if raw.is_a?(Hash)
          raw["selected_modifiers"] || raw[:selected_modifiers]
        end

      return [] if selected.blank?
      return [] unless selected.is_a?(Array)

      selected.filter_map do |mod|
        next unless mod.is_a?(Hash)

        name = mod["name"] || mod[:name]
        next if name.blank?

        price = (mod["price"] || mod[:price] || 0).to_f
        { name: name.to_s, price: price }
      end
    end
  end
end
