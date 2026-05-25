# frozen_string_literal: true

require "test_helper"

class Demo::EnvironmentSetupTest < ActiveSupport::TestCase
  include TestFactories

  test "call creates org two tenants pts and demo users" do
    cat = create_category!(slug: "demo-cat-#{SecureRandom.hex(3)}")
    p1 = create_product!(category: cat, slug: "demo-prod-#{SecureRandom.hex(3)}", name: "Demo Latte")
    p1.update!(base_price: 200, is_active: true)

    result = Demo::EnvironmentSetup.call(load_catalog: false)

    assert_equal Demo::EnvironmentSetup::ORG_SLUG, result.organization.slug
    assert_equal Demo::EnvironmentSetup::TENANT_A_SLUG, result.tenant_a.slug
    assert_equal Demo::EnvironmentSetup::TENANT_B_SLUG, result.tenant_b.slug
    assert_equal result.organization.id, result.tenant_a.organization_id
    assert_equal result.organization.id, result.tenant_b.organization_id

    pts_a = ProductTenantSetting.find_by(tenant_id: result.tenant_a.id, product_id: p1.id)
    pts_b = ProductTenantSetting.find_by(tenant_id: result.tenant_b.id, product_id: p1.id)
    assert pts_a, "PTS for point A expected"
    assert pts_b, "PTS for point B expected"
    assert_equal BigDecimal("200"), pts_a.price
    assert_equal BigDecimal("210"), pts_b.price

    uk = User.find_by!(email: "uk@demo.coffeeos.local")
    assert uk.uk_global_admin?
    assert_equal result.tenant_a.id, uk.tenant_id

    franchise = User.find_by!(email: "franchise@demo.coffeeos.local")
    assert franchise.franchise_manager?
    assert_equal result.organization.id, franchise.organization_id

    barista_b = User.find_by!(email: "barista-b@demo.coffeeos.local")
    assert barista_b.has_role?("barista")
    assert_equal result.tenant_b.id, barista_b.tenant_id

    gm_a = User.find_by!(email: "gm-a@demo.coffeeos.local")
    assert gm_a.has_role?("general_manager")
    assert_equal result.tenant_a.id, gm_a.tenant_id

    pk_manager = User.find_by!(email: "pk-manager@demo.coffeeos.local")
    assert pk_manager.has_role?("prep_kitchen_manager")
    assert_equal result.tenant_kitchen.id, pk_manager.tenant_id
    assert result.tenant_kitchen.production_kitchen?

    pk_worker = User.find_by!(email: "pk-worker@demo.coffeeos.local")
    assert pk_worker.has_role?("prep_kitchen_worker")
    assert_equal result.tenant_kitchen.id, pk_worker.tenant_id

    assert FeatureFlag.find_by!(tenant_id: result.tenant_kitchen.id, module: "prep_kitchen").enabled
    assert_not FeatureFlag.find_by!(tenant_id: result.tenant_a.id, module: "prep_kitchen").enabled

    assert barista_b.authenticate(Demo::EnvironmentSetup::DEMO_PASSWORD)
    assert pk_worker.authenticate(Demo::EnvironmentSetup::DEMO_PASSWORD)

    assert OrderCancelReason.exists?(code: "barista_cancel")
    assert OrderCancelReason.exists?(code: "customer_changed_mind")
    assert OrderCancelReason.exists?(code: "other")

    barista_a = User.find_by!(email: "barista-a@demo.coffeeos.local")
    open_shift = CashShift.find_by!(tenant_id: result.tenant_a.id, status: "open")
    assert_equal barista_a.id, open_shift.opened_by_id

    ingredient = Ingredient.active.order(:name).first
    if ingredient
      stock = IngredientTenantStock.find_by!(tenant_id: result.tenant_kitchen.id, ingredient_id: ingredient.id)
      assert stock.qty >= 10
    end
  end

  test "call is idempotent" do
    create_category!(slug: "demo-cat-idem-#{SecureRandom.hex(3)}")
    first = Demo::EnvironmentSetup.call(load_catalog: false)
    second = Demo::EnvironmentSetup.call(load_catalog: false)

    assert_equal first.organization.id, second.organization.id
    assert_equal first.tenant_a.id, second.tenant_a.id
    assert_equal first.tenant_b.id, second.tenant_b.id
    assert_equal 1, Organization.where(slug: Demo::EnvironmentSetup::ORG_SLUG).count
    assert_equal 3, Tenant.where(organization_id: first.organization.id, type: "sales_point").count
    assert_equal 1, Tenant.where(organization_id: first.organization.id, type: "production_kitchen").count
    assert_equal 4, Tenant.where(organization_id: first.organization.id).count
    assert_equal first.users_count, second.users_count
  end

  test "load_catalog loads shop products and pts for both tenants" do
    result = Demo::EnvironmentSetup.call(load_catalog: true)

    assert result.products_count >= 9
    assert result.pts_a_count >= 9
    assert result.pts_b_count >= 9
    assert Category.exists?(slug: "menu-cat-filter")
    assert Product.exists?(slug: "menu-prod-brazil")
  end
end
