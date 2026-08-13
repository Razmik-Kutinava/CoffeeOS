# frozen_string_literal: true

require "test_helper"

# В2 ONBOARDING_CHECKLIST §6 — связность (smoke).
class Platform::OnboardingConnectivityTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "onboard-conn-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "onboard-conn-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-conn-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    @category = create_category!
    @product = create_product!(category: @category, slug: "onboard-conn-prod-#{SecureRandom.hex(4)}")
    @product.update!(base_price: 350, is_active: true, name: "Connectivity Latte")

    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "uk catalog price update propagates to onboarded tenant shop vitrina" do
    slug = "onboard-conn-shop-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug, name: "Shop Connect Point")
    tenant = Tenant.find_by!(slug: slug)

    assert_equal 350.to_d, ProductTenantSetting.find_by!(tenant_id: tenant.id, product_id: @product.id).price
    assert_shop_price(tenant.id, 350.0)

    patch platform_menu_product_path(@product), params: {
      product: {
        category_id: @category.id,
        name: @product.name,
        slug: @product.slug,
        description: @product.description,
        base_price: 475,
        sort_order: @product.sort_order,
        is_active: true
      }
    }
    assert_response :redirect

    assert_equal 475.to_d, ProductTenantSetting.find_by!(tenant_id: tenant.id, product_id: @product.id).reload.price
    assert_shop_price(tenant.id, 475.0)
  end

  test "barista order from onboarded tenant appears on manager shift view" do
    slug = "onboard-conn-barista-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug, name: "Barista Connect Point")
    tenant = Tenant.find_by!(slug: slug)

    post open_as_manager_platform_tenant_path(tenant)

    barista_email = "conn-bar-#{SecureRandom.hex(4)}@test.local"
    gm_email = "conn-gm-#{SecureRandom.hex(4)}@test.local"
    post manager_staff_members_path, params: {
      user: { name: "Conn Barista", email: barista_email, password: "pass123456" },
      role_codes: %w[barista]
    }
    post manager_staff_members_path, params: {
      user: { name: "Conn GM", email: gm_email, password: "pass123456" },
      role_codes: %w[general_manager]
    }

    barista = User.find_by!(email: barista_email)
    gm = User.find_by!(email: gm_email)
    shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    delete logout_path
    login_as!(barista, password: "pass123456")

    post "/barista/orders", params: {
      cart_items: [ { "product_id" => @product.id, "quantity" => 1 } ],
      payment_method: "cash"
    }
    assert_response :redirect

    order = Order.where(tenant_id: tenant.id, cash_shift_id: shift.id).order(created_at: :desc).first
    assert order, "barista должен создать заказ в открытой смене"

    login_as!(gm, password: "pass123456")
    get manager_shift_path(shift)
    assert_response :success
    assert_includes response.body, order.order_number

    get manager_orders_path
    assert_response :success
    assert_includes response.body, order.order_number
  end

  test "prep kitchen movement after onboarding is scoped to own tenant only" do
    slug_a = "onboard-conn-pk-a-#{SecureRandom.hex(3)}"
    slug_b = "onboard-conn-pk-b-#{SecureRandom.hex(3)}"

    post platform_tenants_path, params: kitchen_payload(slug: slug_a, name: "Kitchen A")
    kitchen_a = Tenant.find_by!(slug: slug_a)

    post platform_tenants_path, params: kitchen_payload(slug: slug_b, name: "Kitchen B")
    kitchen_b = Tenant.find_by!(slug: slug_b)

    post open_as_manager_platform_tenant_path(kitchen_a)
    email = "conn-pk-#{SecureRandom.hex(4)}@test.local"
    post manager_staff_members_path, params: {
      user: { name: "PK Manager A", email: email, password: "pass123456" },
      role_codes: %w[prep_kitchen_manager]
    }

    ingredient_a = Ingredient.create!(name: "Ing-A-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    stock_a = IngredientTenantStock.create!(tenant: kitchen_a, ingredient: ingredient_a, qty: 10, min_qty: 2)

    ingredient_b = Ingredient.create!(name: "Ing-B-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    other_manager = create_user!(
      tenant: kitchen_b,
      role_codes: %w[prep_kitchen_manager],
      email: "conn-pk-b-#{SecureRandom.hex(3)}@test.local"
    )
    foreign_movement = StockMovement.create!(
      tenant: kitchen_b,
      movement_type: "receipt",
      status: "draft",
      created_by: other_manager
    )
    StockMovementItem.create!(movement: foreign_movement, ingredient: ingredient_b, qty_change: 5)

    delete logout_path
    post "/login", params: { email: email, password: "pass123456" }
    assert_redirected_to prep_kitchen_dashboard_path

    assert_difference -> { StockMovement.where(tenant_id: kitchen_a.id, status: "draft").count }, +1 do
      post prep_kitchen_movements_path, params: {
        movement: {
          movement_type: "receipt",
          note: "Onboard connect",
          items: [ { ingredient_id: ingredient_a.id, qty_change: 3, unit_cost: 10 } ]
        }
      }
    end
    assert_response :redirect

    own_movement = StockMovement.where(tenant_id: kitchen_a.id).order(created_at: :desc).first
    post prep_kitchen_confirm_movement_path(own_movement)
    assert_response :redirect
    assert_equal "confirmed", own_movement.reload.status
    assert_equal 13.to_d, stock_a.reload.qty

    post prep_kitchen_confirm_movement_path(foreign_movement)
    assert_response :redirect
    assert_equal "draft", foreign_movement.reload.status
  end

  private

  def assert_shop_price(tenant_id, expected)
    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => tenant_id.to_s }
    assert_response :success
    assert_in_delta expected, response.parsed_body["price"], 0.001
  end

  def sales_point_payload(slug:, name:)
    {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "sales_point",
        status: "active",
        city: "Conn City",
        address: "Conn St 1",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      weekday_schedules: default_weekday_schedules_params,
      modules: { "menu" => "1", "barista" => "1", "kiosk" => "0" }
    }
  end

  def kitchen_payload(slug:, name:)
    {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "production_kitchen",
        status: "active",
        city: "Kitchen City",
        address: "Industrial 1",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      modules: {
        "prep_kitchen" => "1",
        "barista" => "0",
        "menu" => "0",
        "kiosk" => "0",
        "qr_offers" => "0",
        "tv_board" => "0"
      }
    }
  end
end
