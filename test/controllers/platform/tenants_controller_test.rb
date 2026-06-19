# frozen_string_literal: true

require "test_helper"

class Platform::TenantsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!
    @anchor = create_tenant!(organization: @org, slug: "anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-#{SecureRandom.hex(4)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  test "create rolls back tenant if Provision raises an error" do
    slug = "rollback-point-#{SecureRandom.hex(4)}"

    original = Platform::TenantOnboarding::Provision.method(:call)
    Platform::TenantOnboarding::Provision.define_singleton_method(:call) { |**| raise "provision failed" }

    begin
      assert_no_difference "Tenant.count" do
        post "/admin/tenants", params: tenant_create_params(slug: slug, name: "Откат точки")
      end
      assert_response :unprocessable_entity
      assert_nil Tenant.find_by(slug: slug)
    ensure
      Platform::TenantOnboarding::Provision.define_singleton_method(:call, original)
    end
  end

  test "create provisions PTS for catalog products" do
    cat = create_category!
    product = create_product!(category: cat, slug: "shop-item-#{SecureRandom.hex(4)}")
    product.update!(base_price: 220)

    slug = "new-point-#{SecureRandom.hex(4)}"
    assert_difference -> { Tenant.count }, +1 do
      post "/admin/tenants", params: tenant_create_params(
        slug: slug,
        name: "Новая точка",
        modules: { "kiosk" => "1", "barista" => "1" }
      )
    end

    assert_response :redirect
    tenant = Tenant.find_by!(slug: slug)
    pts = ProductTenantSetting.find_by(tenant_id: tenant.id, product_id: product.id)
    assert pts
    assert_equal BigDecimal("220"), pts.price
    assert_equal 1, tenant.weekday_schedules.enabled.count
  end

  test "create requires at least one weekday for sales point" do
    slug = "no-hours-#{SecureRandom.hex(4)}"

    assert_no_difference "Tenant.count" do
      post "/admin/tenants", params: tenant_create_params(
        slug: slug,
        weekday_schedules: empty_weekday_schedules
      )
    end

    assert_response :unprocessable_entity
    assert_nil Tenant.find_by(slug: slug)
  end

  test "update saves weekday schedules" do
    tenant = create_tenant!(organization: @org, slug: "hours-#{SecureRandom.hex(4)}")
    Platform::TenantWeekdaySchedulesSync.call(
      tenant: tenant,
      schedule_params: { "0" => { enabled: "1", opens_at: "09:00", closes_at: "18:00" } }
    )

    patch "/admin/tenants/#{tenant.id}", params: {
      tenant: {
        name: tenant.name,
        slug: tenant.slug,
        organization_id: @org.id,
        type: "sales_point",
        status: "active",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      weekday_schedules: {
        "0" => { enabled: "1", opens_at: "08:00", closes_at: "22:00" },
        "1" => { enabled: "1", opens_at: "08:00", closes_at: "22:00" }
      }
    }

    assert_response :redirect
    tenant.reload
    assert_equal 2, tenant.weekday_schedules.enabled.count
    mon = tenant.weekday_schedules.find_by!(weekday: 0)
    assert_equal "08:00", mon.opens_at.strftime("%H:%M")
  end

  private

  def tenant_create_params(slug:, name: "Точка", weekday_schedules: default_weekday_schedules, modules: nil)
    params = {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "sales_point",
        status: "active",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      weekday_schedules: weekday_schedules
    }
    params[:modules] = modules if modules
    params
  end

  def default_weekday_schedules
    {
      "0" => { enabled: "1", opens_at: "09:00", closes_at: "21:00" }
    }
  end

  def empty_weekday_schedules
    TenantWeekdaySchedule::WEEKDAYS.each_value.to_h { |wd| [wd.to_s, { enabled: "0" }] }
  end
end
