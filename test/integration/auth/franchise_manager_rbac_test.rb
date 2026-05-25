# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: franchise_manager — просмотр своих точек; без POS и редактирования меню.
class Auth::FranchiseManagerRbacTest < ActionDispatch::IntegrationTest
  FORBIDDEN_PANELS = [
    [:barista, :barista_dashboard_path],
    [:prep_kitchen, :prep_kitchen_dashboard_path],
    [:platform, :platform_root_path]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "fm-org-#{SecureRandom.hex(3)}")
    @other_org = create_organization!(slug: "fm-other-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "FM Point A", slug: "fm-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "FM Point B", slug: "fm-b-#{SecureRandom.hex(4)}")
    @foreign_tenant = create_tenant!(organization: @other_org, name: "Foreign", slug: "fm-x-#{SecureRandom.hex(4)}")

    @franchise_manager = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "fm-#{SecureRandom.hex(3)}@test.local",
      name: "Franchise Owner"
    )

    category = create_category!
    product = create_product!(category: category, name: "FM Product")
    @pts_a = enable_product_for_tenant!(tenant: @tenant_a, product: product, price: 111)
    @pts_b = enable_product_for_tenant!(tenant: @tenant_b, product: product, price: 222)

    login_as!(@franchise_manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "franchise_manager can open manager dashboard and switch between own tenants" do
    get manager_dashboard_path
    assert_response :success
    assert_includes response.body, @tenant_a.name

    post manager_switch_tenant_path, params: { tenant_id: @tenant_b.id }
    follow_redirect!
    assert_response :success
    assert_includes response.body, @tenant_b.name

    get manager_orders_path
    assert_response :success
  end

  test "franchise_manager cannot switch to tenant outside organization" do
    post manager_switch_tenant_path, params: { tenant_id: @foreign_tenant.id }
    assert_redirected_to manager_dashboard_path
    follow_redirect!
    assert_match /нет доступа/i, flash[:alert].to_s
  end

  test "franchise_manager menu is read only without price edit form" do
    post manager_switch_tenant_path, params: { tenant_id: @tenant_a.id }
    follow_redirect!

    get manager_menu_path
    assert_response :success
    assert_includes response.body, "111.0"
    assert_no_match(/Сохранить цену/, response.body)
  end

  test "franchise_manager cannot patch menu price even for own network tenant" do
    post manager_switch_tenant_path, params: { tenant_id: @tenant_b.id }
    follow_redirect!

    patch manager_menu_setting_price_path(@pts_b), params: { product_tenant_setting: { price: 999 } }

    assert_response :redirect
    assert_equal 222.to_d, @pts_b.reload.price.to_d
  end

  test "franchise_manager sees selected tenant menu not other organization" do
    foreign_product = create_product!(category: create_category!, name: "Foreign Product")
    foreign_pts = enable_product_for_tenant!(tenant: @foreign_tenant, product: foreign_product, price: 500)

    post manager_switch_tenant_path, params: { tenant_id: @tenant_a.id }
    follow_redirect!

    get manager_menu_path
    assert_response :success
    assert_includes response.body, "111.0"
    assert_not_includes response.body, foreign_pts.price.to_s
  end

  test "franchise_manager is redirected from pos prep kitchen and platform admin" do
    FORBIDDEN_PANELS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "franchise_manager не должен видеть #{path_helper}"
    end
  end
end
