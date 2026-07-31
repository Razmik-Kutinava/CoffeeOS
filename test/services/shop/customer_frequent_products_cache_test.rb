# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг B3 (ТЗ Шаг 3):
# кэш shop/freq/#{tenant_id}/#{customer_id} с TTL 30 минут,
# принудительный сброс при создании заказа (OrderCreator) и оплате (PaymentStatusUpdater).
class Shop::CustomerFrequentProductsCacheTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @tenant = create_tenant!(slug: "freqc-#{SecureRandom.hex(3)}")
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "freqc-#{SecureRandom.hex(4)}@example.com")
    @category = create_category!(name: "Черный")
    @product = create_product!(category: @category, name: "Бамбл")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
    Rails.cache.clear
  end

  teardown { Current.reset }

  test "cache key format and TTL constant" do
    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_equal "shop/freq/v2/#{@tenant.id}/#{@customer.id}", key
    assert_equal 30.minutes, Shop::CustomerFrequentProductsService::CACHE_TTL
  end

  test "cached_call stores result in Rails.cache and serves stale data within TTL" do
    create_paid_order!(created_at: 1.day.ago)

    first = cached_call
    assert_equal [ @product.id ], first.map { |i| i[:product_id] }

    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_not_nil Rails.cache.read(key), "результат должен лежать в Rails.cache"

    # Новые данные в БД не видны, пока живёт кэш
    another = create_product!(category: @category, name: "Кофе-тоник")
    enable_product_for_tenant!(tenant: @tenant, product: another, price: 300)
    2.times { create_paid_order!(product: another, created_at: 1.hour.ago) }

    assert_equal first, cached_call, "внутри TTL отдаётся кэш без пересчёта"
  end

  test "cache expires after 30 minutes TTL" do
    create_paid_order!(created_at: 1.day.ago)
    first = cached_call
    assert_equal 1, first.length

    another = create_product!(category: @category, name: "Матча")
    enable_product_for_tenant!(tenant: @tenant, product: another, price: 300)
    2.times { create_paid_order!(product: another, created_at: 1.hour.ago) }

    travel 31.minutes do
      refreshed = cached_call
      assert_equal 2, refreshed.length, "после TTL кэш пересчитывается"
    end
  end

  # Ревью (замечание 3): bust_cache! вызывается в hot-path (создание заказа,
  # callback оплаты) — деградация кэш-хранилища не должна ронять заказ/оплату.
  test "bust_cache! never raises when cache store fails (hot-path safety)" do
    cache = Rails.cache
    cache.define_singleton_method(:delete) { |*_a, **_kw| raise StandardError, "cache store down" }
    begin
      assert_nothing_raised do
        Shop::CustomerFrequentProductsService.bust_cache!(tenant_id: @tenant.id, customer_id: @customer.id)
      end
    ensure
      cache.singleton_class.remove_method(:delete)
    end
  end

  test "bust_cache! forces recompute" do
    create_paid_order!(created_at: 1.day.ago)
    cached_call

    another = create_product!(category: @category, name: "Матча")
    enable_product_for_tenant!(tenant: @tenant, product: another, price: 300)
    2.times { create_paid_order!(product: another, created_at: 1.hour.ago) }

    Shop::CustomerFrequentProductsService.bust_cache!(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_equal 2, cached_call.length
  end

  test "OrderCreator invalidates frequent products cache on order creation" do
    create_paid_order!(created_at: 1.day.ago)
    cached_call
    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_not_nil Rails.cache.read(key)

    email = @customer.email
    session = {
      shop_cart: [ { "product_id" => @product.id, "quantity" => 1, "selected_modifiers" => [] } ]
    }
    Shop::EmailVerificationSession.mark_verified!(session, @tenant.id, email)
    Shop::OrderCreator.new(session, tenant: @tenant).call!(
      { payment_method: "cash", email: email, name: "Test Customer" }
    )

    assert_nil Rails.cache.read(key), "создание заказа должно сбрасывать кэш shop/freq"
  end

  test "PaymentStatusUpdater invalidates cache when payment succeeds" do
    order = create_paid_order!(created_at: 1.hour.ago, status: :pending_payment)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "shop",
      status: :pending
    )

    cached_call
    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_not_nil Rails.cache.read(key)

    Callbacks::PaymentStatusUpdater.new(payment: payment, new_status: "succeeded").call!

    assert_nil Rails.cache.read(key), "подтверждение оплаты должно сбрасывать кэш shop/freq"
  end

  # --- Ревизия 2026-07-31: B3 cache v3 + B4 barista bust ---

  test "cache key is v3 and cached payload includes has_active_order" do
    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_equal "shop/freq/v3/#{@tenant.id}/#{@customer.id}", key,
      "ревизия: ключ v3 (payload с has_active_order)"

    create_paid_order!(created_at: 1.day.ago, status: :issued)
    cached_call

    payload = Rails.cache.read(key)
    assert payload.is_a?(Hash), "кэш хранит Hash { has_active_order, frequent_items }, не голый Array"
    flag = payload[:has_active_order]
    flag = payload["has_active_order"] if flag.nil?
    items = payload[:frequent_items] || payload["frequent_items"]
    assert_equal false, flag
    assert_equal 1, items.length
  end

  test "Barista OrderStatusUpdateService busts frequent cache on issued" do
    user = create_user!(tenant: @tenant, role_codes: %w[barista])
    shift = open_cash_shift!(tenant: @tenant, opened_by: user)
    create_paid_order!(created_at: 2.days.ago, status: :issued)
    order = create_paid_order!(created_at: 1.hour.ago, status: :accepted)
    order.update!(cash_shift: shift)

    cached_call
    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_not_nil Rails.cache.read(key)

    # accepted → preparing → ready → issued
    %w[preparing ready issued].each do |status|
      Barista::OrderStatusUpdateService.new(
        order: order.reload,
        new_status: status,
        user_id: user.id
      ).call!
    end

    assert_nil Rails.cache.read(key),
      "переход в issued (терминал) должен сбрасывать кэш, чтобы UI снова увидел повтор"
  end

  test "Barista OrderStatusUpdateService busts frequent cache on cancelled" do
    user = create_user!(tenant: @tenant, role_codes: %w[barista])
    shift = open_cash_shift!(tenant: @tenant, opened_by: user)
    create_paid_order!(created_at: 2.days.ago, status: :issued)
    order = create_paid_order!(created_at: 1.hour.ago, status: :accepted)
    order.update!(cash_shift: shift)

    cached_call
    key = Shop::CustomerFrequentProductsService.cache_key(tenant_id: @tenant.id, customer_id: @customer.id)
    assert_not_nil Rails.cache.read(key)

    Barista::OrderStatusUpdateService.new(
      order: order.reload,
      new_status: "cancelled",
      user_id: user.id
    ).call!

    assert_nil Rails.cache.read(key),
      "отмена активного заказа должна сбрасывать кэш"
  end

  private

  def cached_call
    Shop::CustomerFrequentProductsService.cached_call(customer_id: @customer.id, tenant_id: @tenant.id)
  end

  def create_paid_order!(product: @product, created_at: Time.current, status: :accepted)
    order = Order.create!(
      tenant: @tenant,
      customer_id: @customer.id,
      order_number: "FRQC-#{SecureRandom.hex(4)}",
      source: :mobile,
      status: status,
      total_amount: 250,
      discount_amount: 0,
      final_amount: 250,
      created_at: created_at
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 250,
      total_price: 250,
      modifier_options: {}
    )
    order
  end
end
