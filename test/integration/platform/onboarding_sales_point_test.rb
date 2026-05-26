# frozen_string_literal: true

require "test_helper"
require_relative "../../support/rls_test_helper"

# В2 ONBOARDING_CHECKLIST §2 — точка продаж через УК.
class Platform::OnboardingSalesPointTest < ActionDispatch::IntegrationTest
  include TestFactories
  include RlsTestHelper

  self.use_transactional_tests = false

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "onboard-sp-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "onboard-sp-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-sp-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)

    @category = create_category!
    @product = create_product!(category: @category, slug: "onboard-catalog-#{SecureRandom.hex(4)}")
    @product.update!(base_price: 350, is_active: true)

    @shop_domain_prev = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "shop.example.com"

    @created_tenant_ids = []
    @created_order_ids = []
    @created_user_ids = []
    @created_shift_ids = []
  end

  teardown do
    ENV["SHOP_BASE_DOMAIN"] = @shop_domain_prev
    Rack::Attack.enabled = @rack_attack_was_enabled

    disable_rls_on_mvp_tables!
    Order.where(id: @created_order_ids).delete_all
    CashShift.where(id: @created_shift_ids).delete_all
    User.where(id: @created_user_ids).delete_all
    Tenant.where(id: @created_tenant_ids).delete_all
  end

  test "GET /admin/tenants/new includes address city slug and organization" do
    get new_platform_tenant_path(organization_id: @org.id)

    assert_response :success
    assert_select "select[name='tenant[organization_id]']"
    assert_select "input[name='tenant[name]']"
    assert_select "input[name='tenant[slug]']"
    assert_select "input[name='tenant[city]']"
    assert_select "input[name='tenant[address]']"
    assert_select "select[name='tenant[type]'] option[value='sales_point']"
  end

  test "uk creates three sales points with address city and menu barista modules" do
    slugs = 3.times.map { |i| "onboard-sp-#{i}-#{SecureRandom.hex(3)}" }

    slugs.each_with_index do |slug, i|
      assert_difference -> { Tenant.count }, +1 do
        post platform_tenants_path, params: tenant_payload(
          slug: slug,
          name: "Point #{i + 1}",
          city: "City #{i + 1}",
          address: "Street #{i + 1}, #{100 + i}"
        )
      end
      assert_response :redirect

      tenant = Tenant.find_by!(slug: slug)
      @created_tenant_ids << tenant.id

      assert_equal @org.id, tenant.organization_id
      assert_equal "sales_point", tenant.type
      assert_equal "City #{i + 1}", tenant.city
      assert_equal "Street #{i + 1}, #{100 + i}", tenant.address
      assert FeatureFlag.find_by!(tenant_id: tenant.id, module: "menu").enabled
      assert FeatureFlag.find_by!(tenant_id: tenant.id, module: "barista").enabled
      assert_not FeatureFlag.find_by!(tenant_id: tenant.id, module: "kiosk").enabled
    end

    assert_equal 3, Tenant.where(organization_id: @org.id, type: "sales_point").where(slug: slugs).count
  end

  test "create flash includes subdomain shop url when SHOP_BASE_DOMAIN set" do
    slug = "onboard-flash-#{SecureRandom.hex(4)}"

    post platform_tenants_path, params: tenant_payload(
      slug: slug,
      name: "Flash Point",
      city: "Moscow",
      address: "Tverskaya 1"
    )

    assert_redirected_to platform_tenants_path
    assert_match %r{http://#{slug}\.shop\.example\.com/shop}, flash[:notice]

    tenant = Tenant.find_by!(slug: slug)
    @created_tenant_ids << tenant.id
  end

  test "onboarded tenant shop menu is not empty after provision" do
    slug = "onboard-menu-#{SecureRandom.hex(4)}"

    post platform_tenants_path, params: tenant_payload(
      slug: slug,
      name: "Menu Point",
      city: "SPB",
      address: "Nevsky 10"
    )

    tenant = Tenant.find_by!(slug: slug)
    @created_tenant_ids << tenant.id

    pts = ProductTenantSetting.find_by(tenant_id: tenant.id, product_id: @product.id)
    assert pts, "Provision должен создать PTS для активного продукта каталога"

    get "/shop/api/categories", headers: { "X-Shop-Tenant" => tenant.id.to_s }
    assert_response :success

    products = response.parsed_body["data"].flat_map { |c| c["products"] }
    assert products.any?, "витрина должна показывать продукты после онбординга"
  end

  test "orders on onboarded tenant A are not visible under tenant B rls context" do
    slug_a = "onboard-rls-a-#{SecureRandom.hex(3)}"
    slug_b = "onboard-rls-b-#{SecureRandom.hex(3)}"

    post platform_tenants_path, params: tenant_payload(slug: slug_a, name: "RLS A", city: "A", address: "A st")
    tenant_a = Tenant.find_by!(slug: slug_a)
    @created_tenant_ids << tenant_a.id

    post platform_tenants_path, params: tenant_payload(slug: slug_b, name: "RLS B", city: "B", address: "B st")
    tenant_b = Tenant.find_by!(slug: slug_b)
    @created_tenant_ids << tenant_b.id

    barista_a = create_user!(tenant: tenant_a, role_codes: %w[barista], email: "ba-#{SecureRandom.hex(3)}@test.local")
    barista_b = create_user!(tenant: tenant_b, role_codes: %w[barista], email: "bb-#{SecureRandom.hex(3)}@test.local")
    @created_user_ids.push(barista_a.id, barista_b.id)

    shift_a = open_cash_shift!(tenant: tenant_a, opened_by: barista_a)
    shift_b = open_cash_shift!(tenant: tenant_b, opened_by: barista_b)
    @created_shift_ids.push(shift_a.id, shift_b.id)

    order_a = Order.create!(
      tenant: tenant_a,
      cash_shift: shift_a,
      order_number: "OA-#{SecureRandom.hex(4)}",
      status: "accepted",
      source: "manual",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    order_b = Order.create!(
      tenant: tenant_b,
      cash_shift: shift_b,
      order_number: "OB-#{SecureRandom.hex(4)}",
      status: "accepted",
      source: "manual",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    @created_order_ids.push(order_a.id, order_b.id)

    with_rls_tenant_context(tenant_id: tenant_a.id, user_id: barista_a.id) do
      ids = Order.pluck(:id)
      assert_includes ids, order_a.id
      assert_not_includes ids, order_b.id
    end
  end

  private

  def tenant_payload(slug:, name:, city:, address:)
    {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "sales_point",
        status: "active",
        city: city,
        address: address,
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      modules: { "menu" => "1", "barista" => "1", "kiosk" => "0" }
    }
  end
end
