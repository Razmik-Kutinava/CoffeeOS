# frozen_string_literal: true

module Shop
  # Секция «повторить» (Quick Repeat Bottom Sheet): частые товары клиента
  # за окно WINDOW_DAYS, сгруппированные по [product_id, modifier_options],
  # топ MAX_REPEAT_ITEMS по частоте, при равенстве — по свежести заказа.
  # Без JOIN в горячем потоке: 4 плоских запроса + агрегация в Ruby.
  class CustomerFrequentProductsService
    WINDOW_DAYS = 45
    MAX_REPEAT_ITEMS = 3
    CACHE_TTL = 30.minutes
    # Учитываем только оформленные заказы (оплаченные/выданные), не черновики и не отмены
    COUNTED_STATUSES = %w[accepted preparing ready issued closed].freeze

    def self.call(customer_id:, tenant_id:)
      new(customer_id: customer_id, tenant_id: tenant_id).call
    end

    def self.cache_key(tenant_id:, customer_id:)
      "shop/freq/#{tenant_id}/#{customer_id}"
    end

    def self.cached_call(customer_id:, tenant_id:)
      Rails.cache.fetch(cache_key(tenant_id: tenant_id, customer_id: customer_id), expires_in: CACHE_TTL) do
        call(customer_id: customer_id, tenant_id: tenant_id)
      end
    end

    # Сброс при создании заказа (OrderCreator) и подтверждении оплаты (PaymentStatusUpdater)
    def self.bust_cache!(tenant_id:, customer_id:)
      return if customer_id.blank?

      Rails.cache.delete(cache_key(tenant_id: tenant_id, customer_id: customer_id))
    end

    def initialize(customer_id:, tenant_id:)
      @customer_id = customer_id
      @tenant_id = tenant_id
    end

    def call
      return [] if @customer_id.blank?

      order_dates = recent_order_dates
      return [] if order_dates.empty?

      groups = top_groups(order_items_for(order_dates.keys), order_dates)
      build_items(groups)
    end

    private

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

    # Группировка [product_id, modifier_options] → сортировка частота ↓, свежесть ↓
    def top_groups(item_rows, order_dates)
      item_rows
        .group_by { |(_oid, product_id, modifiers)| [ product_id, modifiers ] }
        .map do |(product_id, modifiers), rows|
          last_at = rows.map { |(oid, *)| order_dates[oid] }.compact.max
          { product_id: product_id, modifier_options: modifiers, count: rows.size, last_at: last_at }
        end
        .sort_by { |g| [ -g[:count], -g[:last_at].to_f ] }
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
          modifier_options: group[:modifier_options]
        }
      end.first(MAX_REPEAT_ITEMS)
    end
  end
end
