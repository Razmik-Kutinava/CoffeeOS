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
      compact_session_cart!
    end

    def add!(product_id:, quantity:, selected_modifiers:)
      product = Product.find(product_id)
      raise ActiveRecord::RecordNotFound, "Товар не найден" unless shop_available?(product)

      # Проверка на общее количество товаров в корзине
      current_total = @session[SESSION_KEY].sum { |l| l["quantity"].to_i }
      if current_total >= MAX_CART_ITEMS
        raise ActiveRecord::RecordNotFound, "Максимум #{MAX_CART_ITEMS} товаров в корзине"
      end

      mods = ModifierSelection.build(product: product, selected_modifiers: selected_modifiers)
      line = {
        "product_id" => product.id,
        "quantity" => quantity.to_i.clamp(1, MAX_ITEM_QUANTITY),
        "selected_modifiers" => compact_modifiers(mods[:selected_modifiers])
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
        if current_total + line["quantity"] > MAX_CART_ITEMS
          raise ActiveRecord::RecordNotFound, "Максимум #{MAX_CART_ITEMS} товаров в корзине"
        end
        @session[SESSION_KEY] << line
      end
      touch_cart_session!
      self
    end

    # S4-блок-2: замена модификаторов строки корзины.
    # Если новая комбинация совпадает с другой строкой — слияние количества, старая строка удаляется.
    def replace_line!(index, selected_modifiers:, quantity: nil)
      i = index.to_i
      old_line = @session[SESSION_KEY][i]
      raise ActiveRecord::RecordNotFound, "Строка корзины не найдена" unless old_line

      product = Product.find(old_line["product_id"])
      raise ActiveRecord::RecordNotFound, "Товар не найден" unless shop_available?(product)

      mods = ModifierSelection.build(product: product, selected_modifiers: selected_modifiers)
      new_qty = quantity ? quantity.to_i.clamp(1, MAX_ITEM_QUANTITY) : old_line["quantity"]

      new_line = {
        "product_id" => old_line["product_id"],
        "quantity"   => new_qty,
        "selected_modifiers" => compact_modifiers(mods[:selected_modifiers])
      }
      new_key = line_key(new_line)

      # Ищем другую строку с той же сигнатурой (product_id + modifiers)
      other_indices = (0...@session[SESSION_KEY].size).reject { |j| j == i }
      merge_idx = other_indices.find { |j| line_key(@session[SESSION_KEY][j]) == new_key }

      if merge_idx
        merged_qty = (@session[SESSION_KEY][merge_idx]["quantity"] + new_qty).clamp(1, MAX_ITEM_QUANTITY)
        @session[SESSION_KEY][merge_idx]["quantity"] = merged_qty
        @session[SESSION_KEY].delete_at(i)
      else
        @session[SESSION_KEY][i] = new_line
      end

      touch_cart_session!
      self
    end

    def remove!(index)
      @session[SESSION_KEY].delete_at(index.to_i)
      touch_cart_session!
    end

    def update_quantity!(index, delta)
      i = index.to_i
      return unless @session[SESSION_KEY][i]

      new_qty = @session[SESSION_KEY][i]["quantity"] + delta.to_i
      if delta.to_i.positive? && new_qty > MAX_ITEM_QUANTITY
        raise ActiveRecord::RecordNotFound, "Максимум #{MAX_ITEM_QUANTITY} единиц товара"
      end

      if new_qty < 1
        raise ActiveRecord::RecordNotFound, "Минимум 1 единица товара"
      end

      @session[SESSION_KEY][i]["quantity"] = new_qty
      touch_cart_session!
    end

    def clear!
      @session[SESSION_KEY] = []
      touch_cart_session!
    end

    def json_lines
      # FIX: Load all products and tenant settings at once to avoid N+1 queries
      product_ids = @session[SESSION_KEY].map { |line| line["product_id"] }
      products = Product.where(id: product_ids).index_by(&:id)
      tenant_settings = ProductTenantSetting.where(product_id: product_ids, tenant_id: @tenant_id).index_by(&:product_id)
      # В cookie храним только id модификаторов — name/price восстанавливаем из БД одним запросом.
      option_lookup = modifier_option_lookup

      lines = @session[SESSION_KEY].map.with_index do |line, idx|
        product = products[line["product_id"]]
        raise ActiveRecord::RecordNotFound, "Товар недоступен" unless shop_available?(product)

        setting = tenant_settings[product.id]
        raise ActiveRecord::RecordNotFound, "Настройки цены для товара '#{product.name}' не найдены для данной точки" unless setting

        unit_price = line_unit_price(product, line, setting)
        qty = line["quantity"]
        removed_modifiers = removed_modifiers_for(product, line)
        {
          index: idx,
          product_id: product.id,
          product_name: product.name,
          quantity: qty,
          price: setting.price.to_f,
          image_url: product.image_url,
          selected_modifiers: hydrate_modifiers(line["selected_modifiers"], option_lookup),
          removed_modifiers: removed_modifiers,
          unit_total: unit_price.to_f,
          line_total: (unit_price * qty).to_f
        }
      end
      { items: lines, total: lines.sum { |l| l[:line_total] } }
    end

    private

    # Rails не помечает session dirty при in-place изменении массива — cookie не обновляется между HTTP-запросами.
    def touch_cart_session!
      compact_session_cart!
      @session[SESSION_KEY] = @session[SESSION_KEY].dup
    end

    # removed_modifiers не храним в cookie-сессии — иначе ActionDispatch::CookieOverflow (~4KB).
    # selected_modifiers сжимаем до одних id — name/price восстанавливаются из БД в json_lines.
    def compact_session_cart!
      @session[SESSION_KEY].each do |line|
        line.delete("removed_modifiers")
        line["selected_modifiers"] = compact_modifiers(line["selected_modifiers"]) if line.key?("selected_modifiers")
      end
    end

    # В cookie кладём только id (или name/price когда id отсутствует — кастомный модификатор).
    def compact_modifiers(mods)
      Array(mods).map do |m|
        h = m.respond_to?(:to_unsafe_h) ? m.to_unsafe_h : m
        id = (h["id"] || h[:id]).presence
        if id
          { "id" => id }
        else
          { "id" => nil, "name" => h["name"] || h[:name], "price" => (h["price"] || h[:price]).to_f }
        end
      end
    end

    # Карта id опции → {name, price} для всех модификаторов корзины (1 запрос).
    def modifier_option_lookup
      ids = @session[SESSION_KEY].flat_map { |l| Array(l["selected_modifiers"]).filter_map { |m| m["id"].presence } }
      return {} if ids.empty?

      ProductModifierOption.where(id: ids).index_by { |o| o.id.to_s }
    end

    # Восстанавливаем полный модификатор {id, name, price} по id из карты опций.
    def hydrate_modifiers(mods, option_lookup)
      Array(mods).map do |m|
        id = m["id"].presence
        opt = id && option_lookup[id.to_s]
        if opt
          { "id" => opt.id, "name" => opt.name, "price" => opt.price_delta.to_f }
        else
          { "id" => m["id"], "name" => m["name"], "price" => m["price"].to_f }
        end
      end
    end

    def removed_modifiers_for(product, line)
      ModifierSelection.build(
        product: product,
        selected_modifiers: line["selected_modifiers"]
      )[:removed_modifiers]
    end

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
