# frozen_string_literal: true

require "test_helper"
require_relative "../support/rls_test_helper"

# Веха 1 / блок B: Postgres RLS — точка A не видит данные точки B.
# Новые политики не добавляем (STOP-LIST roadmap); проверяем существующие из миграций.
class RlsTenantIsolationTest < ActiveSupport::TestCase
  include TestFactories
  include RlsTestHelper

  # CREATE ROLE / CREATE POLICY не переживают rollback transactional fixtures.
  self.use_transactional_tests = false

  setup do
    RlsTestBootstrap.ensure_policies!

    @org = create_organization!(slug: "rls-org-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "RLS Point A", slug: "rls-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(organization: @org, name: "RLS Point B", slug: "rls-b-#{SecureRandom.hex(3)}")
    @barista_a = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "rls-bar-a-#{SecureRandom.hex(3)}@test.local")
    @barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "rls-bar-b-#{SecureRandom.hex(3)}@test.local")

    @order_a = create_order!(@tenant_a)
    @order_b = create_order!(@tenant_b)
    @payment_a = create_payment!(@order_a, @tenant_a)
    @payment_b = create_payment!(@order_b, @tenant_b)

    category = create_category!
    product = create_product!(category: category)
    @category = category
    @product = product
    @pts_a = enable_product_for_tenant!(tenant: @tenant_a, product: product, price: 100)
    @pts_b = enable_product_for_tenant!(tenant: @tenant_b, product: product, price: 200)

    @shift_a = open_cash_shift!(tenant: @tenant_a, opened_by: @barista_a)
    @shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: @barista_b)

    ingredient = Ingredient.create!(name: "RLS Ing #{SecureRandom.hex(3)}", unit: "g", is_active: true)
    @ingredient = ingredient
    @stock_a = IngredientTenantStock.create!(tenant: @tenant_a, ingredient: ingredient, qty: 5)
    @stock_b = IngredientTenantStock.create!(tenant: @tenant_b, ingredient: ingredient, qty: 8)
  end

  teardown do
    disable_rls_on_mvp_tables!

    [ @payment_a, @payment_b ].compact.each { |row| row.destroy rescue nil }
    [ @order_a, @order_b ].compact.each { |row| row.destroy rescue nil }
    [ @shift_a, @shift_b ].compact.each { |row| row.destroy rescue nil }
    [ @stock_a, @stock_b, @pts_a, @pts_b ].compact.each { |row| row.destroy rescue nil }
    [ @barista_a, @barista_b ].compact.each { |row| row.destroy rescue nil }
    [ @tenant_a, @tenant_b ].compact.each { |row| row.destroy rescue nil }
    @product&.destroy
    @category&.destroy
    @ingredient&.destroy
    @org&.destroy
  end

  test "mvp tenant tables have existing postgres rls policies" do
    conn = ActiveRecord::Base.connection
    %w[orders payments product_tenant_settings cash_shifts ingredient_tenant_stocks stock_movements].each do |table|
      count = conn.select_value(<<~SQL.squish)
        SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = #{conn.quote(table)}
      SQL
      assert count.to_i.positive?, "ожидались политики RLS на #{table} (миграции stage 1–5)"
    end
  end

  test "tenant a rls context sees only own orders" do
    with_rls_tenant_context(tenant_id: @tenant_a.id, user_id: @barista_a.id) do
      ids = Order.pluck(:id)
      assert_includes ids, @order_a.id
      assert_not_includes ids, @order_b.id
    end
  end

  test "tenant a cannot load tenant b order by id under rls" do
    with_rls_tenant_context(tenant_id: @tenant_a.id, user_id: @barista_a.id) do
      assert_raises(ActiveRecord::RecordNotFound) { Order.find(@order_b.id) }
    end
  end

  test "tenant a rls context sees only own payments" do
    with_rls_tenant_context(tenant_id: @tenant_a.id, user_id: @barista_a.id) do
      payment_ids = Payment.pluck(:id)
      assert_includes payment_ids, @payment_a.id
      assert_not_includes payment_ids, @payment_b.id
    end
  end

  test "tenant a rls context sees only own product tenant settings" do
    with_rls_tenant_context(tenant_id: @tenant_a.id, user_id: @barista_a.id) do
      rows = ProductTenantSetting.where(product_id: @pts_a.product_id)
      assert_includes rows.map(&:id), @pts_a.id
      assert_not_includes rows.map(&:id), @pts_b.id
    end
  end

  test "tenant a rls context sees only own cash shifts" do
    with_rls_tenant_context(tenant_id: @tenant_a.id, user_id: @barista_a.id) do
      ids = CashShift.pluck(:id)
      assert_includes ids, @shift_a.id
      assert_not_includes ids, @shift_b.id
    end
  end

  test "tenant a rls context sees only own ingredient stocks" do
    with_rls_tenant_context(tenant_id: @tenant_a.id, user_id: @barista_a.id) do
      ids = IngredientTenantStock.pluck(:id)
      assert_includes ids, @stock_a.id
      assert_not_includes ids, @stock_b.id
    end
  end

  private

  def create_order!(tenant)
    Order.create!(
      tenant: tenant,
      order_number: "RLS-#{SecureRandom.hex(4)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  def create_payment!(order, tenant)
    Payment.create!(
      order: order,
      tenant: tenant,
      amount: 100,
      method: "cash",
      status: "succeeded",
      provider: "internal"
    )
  end
end
