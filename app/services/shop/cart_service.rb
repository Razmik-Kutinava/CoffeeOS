# frozen_string_literal: true

module Shop
  class CartService
    SESSION_KEY = :shop_cart

    def initialize(session, tenant_id)
      @session = session
      @tenant_id = tenant_id
      @session[SESSION_KEY] ||= []
    end

    def add!(product_id:, quantity:, selected_modifiers:)
      product = Product.find(product_id)
      raise ActiveRecord::RecordNotFound, "Товар не найден" unless shop_available?(product)

      line = {
        "product_id" => product.id,
        "quantity" => quantity.to_i.clamp(1, 99),
        "selected_modifiers" => normalize_modifiers(selected_modifiers)
      }
      key = line_key(line)
      existing = @session[SESSION_KEY].find_index { |l| line_key(l) == key }
      if existing
        @session[SESSION_KEY][existing]["quantity"] += line["quantity"]
      else
        @session[SESSION_KEY] << line
      end
      self
    end

    def remove!(index)
      @session[SESSION_KEY].delete_at(index.to_i)
    end

    def update_quantity!(index, delta)
      i = index.to_i
      return unless @session[SESSION_KEY][i]

      @session[SESSION_KEY][i]["quantity"] += delta.to_i
      @session[SESSION_KEY].delete_at(i) if @session[SESSION_KEY][i]["quantity"] < 1
    end

    def clear!
      @session[SESSION_KEY] = []
    end

    def json_lines
      lines = @session[SESSION_KEY].map.with_index do |line, idx|
        product = Product.find(line["product_id"])
        raise ActiveRecord::RecordNotFound, "Товар недоступен" unless shop_available?(product)

        unit_price = line_unit_price(product, line)
        qty = line["quantity"]
        {
          index: idx,
          product_id: product.id,
          product_name: product.name,
          quantity: qty,
          price: tenant_setting(product).price.to_f,
          image_url: product.image_url,
          selected_modifiers: line["selected_modifiers"],
          unit_total: unit_price.to_f,
          line_total: (unit_price * qty).to_f
        }
      end
      { items: lines, total: lines.sum { |l| l[:line_total] } }
    end

    private

    def tenant_setting(product)
      ProductTenantSetting.find_by!(product_id: product.id, tenant_id: @tenant_id)
    end

    def shop_available?(product)
      ProductTenantSetting.available.exists?(product_id: product.id, tenant_id: @tenant_id) &&
        product.is_active?
    end

    def line_key(line)
      [ line["product_id"], (line["selected_modifiers"] || []).to_json ]
    end

    def normalize_modifiers(mods)
      Array(mods).map do |m|
        h = ActiveSupport::HashWithIndifferentAccess.new(m.respond_to?(:to_unsafe_h) ? m.to_unsafe_h : m)
        {
          "id" => h[:id],
          "name" => h[:name],
          "price" => BigDecimal(h[:price].to_s).to_f
        }
      end
    end

    def line_unit_price(product, line)
      base = tenant_setting(product).price
      mods = line["selected_modifiers"] || []
      extra = mods.sum { |m| verified_modifier_delta(product, m) }
      base + extra
    end

    def verified_modifier_delta(product, m)
      oid = m["id"]
      return BigDecimal(m["price"].to_s) if oid.blank?

      opt = ProductModifierOption.joins(:group)
        .find_by(id: oid, product_modifier_groups: { product_id: product.id })
      opt ? opt.price_delta : BigDecimal(m["price"].to_s)
    end
  end
end
