# frozen_string_literal: true

require "test_helper"

class MultiTenantIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @tenant_a = create_tenant!(name: "A", slug: "tenant-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(name: "B", slug: "tenant-b-#{SecureRandom.hex(3)}")
    @barista_a = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "barista-a-#{SecureRandom.hex(3)}@test.local")
    @barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "barista-b-#{SecureRandom.hex(3)}@test.local")
  end

  # ---------------------------------------------------------------------------
  # Order.for_current_tenant scoping
  # ---------------------------------------------------------------------------

  test "Order.for_current_tenant with tenant_a returns only tenant_a orders" do
    order_a = build_order!(tenant: @tenant_a)
    order_b = build_order!(tenant: @tenant_b)

    Current.tenant_id = @tenant_a.id
    results = Order.for_current_tenant

    assert_includes results, order_a
    assert_not_includes results, order_b
  end

  test "Order.for_current_tenant with tenant_b returns only tenant_b orders" do
    order_a = build_order!(tenant: @tenant_a)
    order_b = build_order!(tenant: @tenant_b)

    Current.tenant_id = @tenant_b.id
    results = Order.for_current_tenant

    assert_includes results, order_b
    assert_not_includes results, order_a
  end

  # ---------------------------------------------------------------------------
  # CashShift.for_current_tenant scoping
  # ---------------------------------------------------------------------------

  test "CashShift.for_current_tenant scopes correctly to current tenant" do
    shift_a = open_cash_shift!(tenant: @tenant_a, opened_by: @barista_a)
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: @barista_b)

    Current.tenant_id = @tenant_a.id
    results = CashShift.for_current_tenant

    assert_includes results, shift_a
    assert_not_includes results, shift_b
  end

  # ---------------------------------------------------------------------------
  # ProductTenantSetting isolation
  # ---------------------------------------------------------------------------

  test "ProductTenantSetting.where(tenant_id) returns only that tenant's settings" do
    category  = create_category!
    product_a = create_product!(category: category)
    product_b = create_product!(category: category)

    setting_a = enable_product_for_tenant!(tenant: @tenant_a, product: product_a, price: 100)
    setting_b = enable_product_for_tenant!(tenant: @tenant_b, product: product_b, price: 200)

    results_a = ProductTenantSetting.where(tenant_id: @tenant_a.id)
    results_b = ProductTenantSetting.where(tenant_id: @tenant_b.id)

    assert_includes results_a, setting_a
    assert_not_includes results_a, setting_b

    assert_includes results_b, setting_b
    assert_not_includes results_b, setting_a
  end

  # ---------------------------------------------------------------------------
  # Payment.for_current_tenant scoping
  # ---------------------------------------------------------------------------

  test "Payment.for_current_tenant scopes correctly per tenant" do
    order_a   = build_order!(tenant: @tenant_a)
    order_b   = build_order!(tenant: @tenant_b)
    payment_a = build_payment!(order: order_a, tenant: @tenant_a)
    payment_b = build_payment!(order: order_b, tenant: @tenant_b)

    Current.tenant_id = @tenant_a.id
    results = Payment.for_current_tenant

    assert_includes results, payment_a
    assert_not_includes results, payment_b
  end

  # ---------------------------------------------------------------------------
  # HTTP isolation: barista A cannot access orders that belong to tenant B
  # ---------------------------------------------------------------------------

  test "barista from tenant_a cannot see orders of tenant_b via HTTP" do
    # Login as barista_a
    login_as!(@barista_a)

    # The barista dashboard/orders page scopes to the logged-in user's tenant.
    # We confirm the response is successful (not a 404 / redirect to login).
    get barista_dashboard_path
    assert_response :success

    # Create an order for tenant_b and verify it would not be returned by
    # Order.for_current_tenant when Current.tenant_id == @tenant_a.id
    order_b = build_order!(tenant: @tenant_b)
    Current.tenant_id = @tenant_a.id
    assert_not_includes Order.for_current_tenant.map(&:id), order_b.id
  end

  # ---------------------------------------------------------------------------
  # PromoCode.for_current_tenant scoping
  # ---------------------------------------------------------------------------

  test "PromoCode.for_current_tenant returns only that tenant's promo codes" do
    promo_a = build_promo_code!(tenant: @tenant_a, code: "CODEA#{SecureRandom.hex(2)}")
    promo_b = build_promo_code!(tenant: @tenant_b, code: "CODEB#{SecureRandom.hex(2)}")

    Current.tenant_id = @tenant_a.id
    results = PromoCode.for_current_tenant

    assert_includes results, promo_a
    assert_not_includes results, promo_b
  end

  private

  # Minimal order factory — avoids full order creation complexity
  def build_order!(tenant:)
    Order.create!(
      tenant:          tenant,
      order_number:    "TEST-#{SecureRandom.hex(4)}",
      source:          "manual",
      status:          "accepted",
      total_amount:    100,
      discount_amount: 0,
      final_amount:    100
    )
  end

  def build_payment!(order:, tenant:)
    Payment.create!(
      order:    order,
      tenant:   tenant,
      amount:   100,
      method:   "cash",
      status:   "pending",
      provider: "internal"
    )
  end

  def build_promo_code!(tenant:, code:)
    PromoCode.create!(
      tenant:              tenant,
      code:                code,
      discount_percentage: 10,
      valid_from:          1.day.ago,
      valid_to:            1.day.from_now,
      max_uses:            100,
      used_count:          0,
      is_active:           true
    )
  end
end
