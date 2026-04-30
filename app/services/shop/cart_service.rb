# frozen_string_literal: true

module Shop
  class CartService
    SESSION_KEY = :shop_cart
    MAX_CART_ITEMS = 50
    MAX_ITEM_QUANTITY = 99

    def initialize(session, tenant_id)
      @session = session
      @tenant_id = tenant_id
      @session[SESSION_KEY] ||= []
    end

    def add!(product_id:, quantity:, selected_modifiers:)
      product = Product.find(product_id)
      raise ActiveRecord::RecordNotFound, "Товар не найден" unless shop_available?(product)

      # Проверка на общее количество товаров в корзине
      current_total = @session[SESSION_KEY].sum { |l| l["quantity"].to_i }
      if current_total >= MAX_CART_ITEMS
        raise ActiveRecord::RecordNotFound, "Максимум #{MAX_CART_ITEMS} товаров в корзине"
      end

      line = {
        "product_id" => product.id,
        "quantity" => quantity.to_i.clamp(1, MAX_ITEM_QUANTITY),
        "selected_modifiers" => normalize_modifiers(selected_modifiers)
      }
      key = line_key(line)
      existing = @session[SESSION_KEY].find_index { |l| line_key(l) == key }
      if existing
        # Проверка при добавлении к существующему товару
        new_quantity = @session[SESSION_KEY][existing]["quantity"] + line["quantity"]
        if new_quantity > MAX_ITEM_QUANTITY
          raise ActiveRecord::RecordNotFound, "Максимум #{MAX_ITEM_QUANTITY} единиц товара"
        end
        @session[SESSION_KEY][existing]["quantity"] += line["quantity"]
      else
        # Проверка при добавлении нового товара
        if current_total + line["quantity"] > MAX_CART_ITEMS
          raise ActiveRecord::RecordNotFound, "Максимум #{MAX_CART_ITEMS} товаров в корзине"
        end
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
      # FIX: Load all products and tenant settings at once to avoid N+1 queries
      product_ids = @session[SESSION_KEY].map { |line| line["product_id"] }
      products = Product.where(id: product_ids).index_by(&:id)
      tenant_settings = ProductTenantSetting.where(product_id: product_ids, tenant_id: @tenant_id).index_by(&:product_id)

      lines = @session[SESSION_KEY].map.with_index do |line, idx|
        product = products[line["product_id"]]
        raise ActiveRecord::RecordNotFound, "Товар недоступен" unless shop_available?(product)

        setting = tenant_settings[product.id]
        raise ActiveRecord::RecordNotFound, "Настройки цены для товара '#{product.name}' не найдены для данной точки" unless setting

        unit_price = line_unit_price(product, line, setting)
        qty = line["quantity"]
        {
          index: idx,
          product_id: product.id,
          product_name: product.name,
          quantity: qty,
          price: setting.price.to_f,
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
      setting = ProductTenantSetting.find_by(product_id: product.id, tenant_id: @tenant_id)
      raise ActiveRecord::RecordNotFound, "Настройки цены для товара '#{product.name}' не найдены для данной точки" unless setting
      setting
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

    def line_unit_price(product, line, setting)
      base = setting.price
      mods = line["selected_modifiers"] || []
      extra = mods.sum { |m| verified_modifier_delta(product, m) }
      base + extra
    end

    def verified_modifier_delta(product, m)
      oid = m["id"]
      return BigDecimal(m["price"].to_s) if oid.blank?

      opt = ProductModifierOption.joins(:group)
        .find_by(id: oid, product_modifier_groups: { product_id: product.id })
      unless opt
        raise ActiveRecord::RecordNotFound, "Модификатор #{oid} не найден для товара #{product.id}"
      end
      opt.price_delta
    end
  end
end
