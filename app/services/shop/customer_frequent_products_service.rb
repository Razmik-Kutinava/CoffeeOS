# frozen_string_literal: true

module Shop
  # Секция «повторить» (Quick Repeat Bottom Sheet): частые товары клиента
  # за окно WINDOW_DAYS, сгруппированные по [product_id, modifier_options],
  # топ MAX_REPEAT_ITEMS по частоте, при равенстве — по свежести заказа.
  # Без JOIN в горячем потоке: плоские запросы + агрегация в Ruby.
  #
  # Ревизия 2026-07-31: при активном заказе (HIDE_REPEAT_STATUSES = Order.active)
  # frequent_items пуст; кэш v3 хранит { has_active_order, frequent_items }.
  # #43 / #42: hide только для «свежих» active (иначе June accepted навечно гасит «повторить»).
  class CustomerFrequentProductsService
    WINDOW_DAYS = 45
    MAX_REPEAT_ITEMS = 3
    CACHE_TTL = 30.minutes
    # Общее окно с Shop::Api::OrdersController#active (#42)
    ACTIVE_ORDERS_WINDOW = 24.hours
    # Учитываем только оформленные заказы (оплаченные/выданные), не черновики и не отмены
    COUNTED_STATUSES = %w[accepted preparing ready issued closed].freeze
    # Скрыть «повторить» пока заказ в работе (= Order.active / #35)
    HIDE_REPEAT_STATUSES = %w[accepted preparing ready].freeze

    def self.call(customer_id:, tenant_id:)
      new(customer_id: customer_id, tenant_id: tenant_id).call
    end

    def self.payload(customer_id:, tenant_id:)
      new(customer_id: customer_id, tenant_id: tenant_id).payload
    end

    def self.cache_key(tenant_id:, customer_id:)
      # v3: payload { has_active_order, frequent_items } (ревизия active-order hide)
      "shop/freq/v3/#{tenant_id}/#{customer_id}"
    end

    # Совместимость: массив frequent_items (как до v3)
    def self.cached_call(customer_id:, tenant_id:)
      cached_payload(customer_id: customer_id, tenant_id: tenant_id)[:frequent_items]
    end

    def self.cached_payload(customer_id:, tenant_id:)
      Rails.cache.fetch(cache_key(tenant_id: tenant_id, customer_id: customer_id), expires_in: CACHE_TTL) do
        payload(customer_id: customer_id, tenant_id: tenant_id)
      end
    end

    # Сброс: OrderCreator, PaymentStatusUpdater, Barista::OrderStatusUpdateService,
    # GuestOrderCancellationService (A6 — иначе has_active_order залипает после cancel).
    # Hot-path: деградация кэша не роняет заказ/оплату/смену статуса.
    def self.bust_cache!(tenant_id:, customer_id:)
      return if customer_id.blank?

      Rails.cache.delete(cache_key(tenant_id: tenant_id, customer_id: customer_id))
    rescue StandardError => e
      Rails.logger.warn("[Shop::FrequentProducts] bust_cache! failed: #{e.class}: #{e.message}")
      nil
    end

    def initialize(customer_id:, tenant_id:)
      @customer_id = customer_id
      @tenant_id = tenant_id
    end

    def call
      payload[:frequent_items]
    end

    def payload
      return { has_active_order: false, frequent_items: [] } if @customer_id.blank?

      active = has_active_order?
      {
        has_active_order: active,
        frequent_items: active ? [] : compute_items
      }
    end

    private

    def has_active_order?
      Order
        .where(tenant_id: @tenant_id, customer_id: @customer_id)
        .where(status: HIDE_REPEAT_STATUSES)
        .where("created_at >= ?", ACTIVE_ORDERS_WINDOW.ago)
        .exists?
    end

    def compute_items
      order_dates = recent_order_dates
      return [] if order_dates.empty?

      groups = top_groups(order_items_for(order_dates.keys), order_dates)
      build_items(groups)
    end

    # { order_id => created_at } за окно — один запрос без JOIN
    def recent_order_dates
      Order
        .where(tenant_id: @tenant_id, customer_id: @customer_id, source: :mobile)
        .where(status: COUNTED_STATUSES)
        .where("created_at >= ?", WINDOW_DAYS.days.ago)
        .pluck(:id, :created_at)
        .to_h
    end

    def order_items_for(order_ids)
      OrderItem
        .where(order_id: order_ids)
        .pluck(:order_id, :product_id, :modifier_options)
    end

    # Группировка [product_id, canonical modifiers] → сортировка частота ↓, свежесть ↓
    def top_groups(item_rows, order_dates)
      item_rows
        .group_by { |(_oid, product_id, modifiers)| [ product_id, normalize_modifier_options(modifiers) ] }
        .map do |(product_id, modifiers), rows|
          best = rows.max_by { |(oid, *)| order_dates[oid].to_f }
          last_oid, = best
          last_at = order_dates[last_oid]
          {
            product_id: product_id,
            modifier_options: modifiers,
            count: rows.size,
            last_at: last_at,
            last_order_id: last_oid
          }
        end
        .sort_by { |g| [ -g[:count], -g[:last_at].to_f ] }
    end

    # FIX-B: {} и {"selected_modifiers":[]} — одна карточка; legacy-плоский jsonb не трогаем
    def normalize_modifier_options(modifiers)
      return { "selected_modifiers" => [] } if modifiers.blank? || !modifiers.is_a?(Hash)

      legacy_only = modifiers.except("removed_modifiers", :removed_modifiers)
      if modifiers.key?("selected_modifiers") || modifiers.key?(:selected_modifiers)
        raw = modifiers["selected_modifiers"] || modifiers[:selected_modifiers]
        selected = Array(raw).filter_map do |mod|
          next unless mod.is_a?(Hash)

          id = mod["id"] || mod[:id]
          next if id.blank?

          { "id" => id.to_s, "name" => (mod["name"] || mod[:name]).to_s }
        end.sort_by { |m| m["id"] }

        return { "selected_modifiers" => selected }
      end

      return { "selected_modifiers" => [] } if legacy_only.blank?

      legacy_only.stringify_keys.sort.to_h
    end

    def build_items(groups)
      product_ids = groups.map { |g| g[:product_id] }.uniq
      settings = ProductTenantSetting
        .where(product_id: product_ids, tenant_id: @tenant_id, is_enabled: true)
        .index_by(&:product_id)
      products = Product.where(id: settings.keys).index_by(&:id)

      groups.filter_map do |group|
        setting = settings[group[:product_id]]
        product = products[group[:product_id]]
        next if setting.nil? || product.nil?

        {
          product_id: product.id,
          name: product.name,
          price: setting.price.to_f,
          image_url: product.image_url,
          modifier_options: group[:modifier_options],
          last_order_id: group[:last_order_id]
        }
      end.first(MAX_REPEAT_ITEMS)
    end
  end
end
