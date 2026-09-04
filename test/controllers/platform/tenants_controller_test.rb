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

  test "create accepts overnight weekday schedule" do
    slug = "overnight-#{SecureRandom.hex(4)}"

    assert_difference -> { Tenant.count }, +1 do
      post "/admin/tenants", params: tenant_create_params(
        slug: slug,
        name: "Жид",
        weekday_schedules: {
          "0" => { enabled: "1", opens_at: "09:23", closes_at: "01:24" }
        }
      )
    end

    assert_response :redirect
    tenant = Tenant.find_by!(slug: slug)
    mon = tenant.weekday_schedules.find_by!(weekday: 0)
    assert mon.enabled?
    assert mon.overnight?
    assert_equal "09:23", mon.opens_at.strftime("%H:%M")
    assert_equal "01:24", mon.closes_at.strftime("%H:%M")
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

  test "update ignores unpermitted weekday schedule keys" do
    other = create_tenant!(organization: @org, slug: "other-#{SecureRandom.hex(4)}")
    tenant = create_tenant!(organization: @org, slug: "secure-#{SecureRandom.hex(4)}")
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
        "0" => { enabled: "1", opens_at: "10:00", closes_at: "20:00", tenant_id: other.id, weekday: 3 }
      }
    }

    assert_response :redirect
    mon = tenant.weekday_schedules.find_by!(weekday: 0)
    assert_equal tenant.id, mon.tenant_id
    assert_equal 0, mon.weekday
    assert_equal "10:00", mon.opens_at.strftime("%H:%M")
  end

  # --- #76 point campaign promo 11₽ ---

  test "create with promo toggle on creates card_binding_promo" do
    slug = "promo-on-#{SecureRandom.hex(4)}"
    assert_difference -> { PointCampaignSetting.count }, +1 do
      post "/admin/tenants", params: tenant_create_params(
        slug: slug,
        name: "Промо точка",
        point_campaign: { card_binding_promo_enabled: "1", card_binding_promo_threshold: "30" }
      )
    end

    assert_response :redirect
    tenant = Tenant.find_by!(slug: slug)
    setting = PointCampaignSetting.find_by!(point_id: tenant.id, campaign_type: "card_binding_promo")
    assert setting.enabled?
    assert_equal 30, setting.threshold
    assert_equal 0, setting.counter
  end

  test "create with promo toggle off stores disabled or skips active campaign" do
    slug = "promo-off-#{SecureRandom.hex(4)}"
    post "/admin/tenants", params: tenant_create_params(
      slug: slug,
      point_campaign: { card_binding_promo_enabled: "0", card_binding_promo_threshold: "30" }
    )

    assert_response :redirect
    tenant = Tenant.find_by!(slug: slug)
    setting = PointCampaignSetting.find_by(point_id: tenant.id, campaign_type: "card_binding_promo")
    assert setting.nil? || !setting.enabled?
  end

  test "update toggle off keeps counter; show lists counter and threshold" do
    tenant = create_tenant!(organization: @org, slug: "promo-edit-#{SecureRandom.hex(4)}")
    Platform::TenantWeekdaySchedulesSync.call(
      tenant: tenant,
      schedule_params: { "0" => { enabled: "1", opens_at: "09:00", closes_at: "21:00" } }
    )
    PointCampaignSetting.create!(
      point_id: tenant.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 20,
      counter: 5,
      config: { "promo_amount_rub" => 11 }
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
      weekday_schedules: { "0" => { enabled: "1", opens_at: "09:00", closes_at: "21:00" } },
      point_campaign: { card_binding_promo_enabled: "0", card_binding_promo_threshold: "20" }
    }

    assert_response :redirect
    setting = PointCampaignSetting.find_by!(point_id: tenant.id, campaign_type: "card_binding_promo")
    refute setting.enabled?
    assert_equal 5, setting.counter

    get "/admin/tenants/#{tenant.id}"
    assert_response :success
    assert_match(/Промо 11/, response.body)
    assert_match(/5/, response.body)
    assert_match(/20/, response.body)
  end

  test "create second point in same city does not inherit campaign" do
    first = create_tenant!(organization: @org, slug: "city-1-#{SecureRandom.hex(3)}", city: "Казань")
    PointCampaignSetting.create!(
      point_id: first.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 99,
      counter: 12,
      config: { "promo_amount_rub" => 11 }
    )

    slug = "city-2-#{SecureRandom.hex(3)}"
    post "/admin/tenants", params: tenant_create_params(
      slug: slug,
      name: "Вторая Казань",
      city: "Казань",
      point_campaign: { card_binding_promo_enabled: "0", card_binding_promo_threshold: "10" }
    )

    assert_response :redirect
    second = Tenant.find_by!(slug: slug)
    inherited = PointCampaignSetting.find_by(point_id: second.id, campaign_type: "card_binding_promo")
    assert inherited.nil? || (!inherited.enabled? && inherited.counter == 0 && inherited.threshold != 99)
  end

  private

  def tenant_create_params(slug:, name: "Точка", weekday_schedules: default_weekday_schedules, modules: nil, point_campaign: nil, city: nil)
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
    params[:tenant][:city] = city if city
    params[:modules] = modules if modules
    params[:point_campaign] = point_campaign if point_campaign
    params
  end

  def default_weekday_schedules
    {
      "0" => { enabled: "1", opens_at: "09:00", closes_at: "21:00" }
    }
  end

  def empty_weekday_schedules
    TenantWeekdaySchedule::WEEKDAYS.each_value.to_h { |wd| [ wd.to_s, { enabled: "0" } ] }
  end
end
