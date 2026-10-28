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

  test "create sales_point issues shop api key and shows raw once on show" do
    slug = "api-key-point-#{SecureRandom.hex(4)}"
    assert_difference -> { ShopApiKey.count }, +1 do
      post "/admin/tenants", params: tenant_create_params(slug: slug, name: "Ключ точка")
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success

    tenant = Tenant.find_by!(slug: slug)
    key = ShopApiKey.usable.find_by!(tenant_id: tenant.id, global_ops: false)
    assert key.token_prefix.present?
    assert_match(/Shop API ключ/, response.body)
    assert_match(key.token_prefix, response.body)
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

  test "update to production_kitchen disables leftover card_binding_promo" do
    tenant = create_tenant!(organization: @org, slug: "to-kitchen-#{SecureRandom.hex(4)}")
    Platform::TenantWeekdaySchedulesSync.call(
      tenant: tenant,
      schedule_params: { "0" => { enabled: "1", opens_at: "09:00", closes_at: "21:00" } }
    )
    PointCampaignSetting.create!(
      point_id: tenant.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 20,
      counter: 3,
      config: { "promo_amount_rub" => 11 }
    )

    patch "/admin/tenants/#{tenant.id}", params: {
      tenant: {
        name: tenant.name,
        slug: tenant.slug,
        organization_id: @org.id,
        type: "production_kitchen",
        status: "active",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      }
    }

    assert_response :redirect
    setting = PointCampaignSetting.find_by!(point_id: tenant.id, campaign_type: "card_binding_promo")
    refute setting.enabled?
    assert_equal 3, setting.counter

    get "/admin/tenants/#{tenant.id}"
    assert_response :success
    refute_match(/Счётчик:/, response.body)
  end

  # --- TASK_115 CODE:BLACK network membership ---

  test "TASK_115 S6 form shows CODE:BLACK checkbox and create saves the flag" do
    get "/admin/tenants/new"
    assert_response :success
    assert_match(/Сеть CODE:BLACK/, response.body)
    assert_match(/name="tenant\[code_black_member\]"/, response.body)

    slug = "cb-create-#{SecureRandom.hex(4)}"
    post "/admin/tenants", params: tenant_create_params(slug: slug, code_black_member: "1")

    assert_response :redirect
    assert Tenant.find_by!(slug: slug).code_black_member
  end

  test "TASK_115 S7 create with flag writes audit log from false to true" do
    slug = "cb-audit-create-#{SecureRandom.hex(4)}"
    post "/admin/tenants", params: tenant_create_params(slug: slug, code_black_member: "1")

    tenant = Tenant.find_by!(slug: slug)
    logs = code_black_logs(tenant)
    assert_equal 1, logs.size
    log = logs.first
    assert_equal @uk.id, log.actor_id
    assert_equal "Tenant", log.entity_type
    assert_equal tenant.id, log.tenant_id
    assert_equal false, log.details["from"]
    assert_equal true, log.details["to"]
    assert log.created_at.present?
  end

  test "TASK_115 S8 create without the checkbox keeps point outside the network and writes no audit" do
    slug = "cb-default-#{SecureRandom.hex(4)}"
    post "/admin/tenants", params: tenant_create_params(slug: slug)

    tenant = Tenant.find_by!(slug: slug)
    assert_equal false, tenant.code_black_member
    assert_empty code_black_logs(tenant)
  end

  test "TASK_115 S6 S7 update toggles the flag and logs each change with actor" do
    tenant = create_hours_tenant!

    patch "/admin/tenants/#{tenant.id}", params: tenant_update_params(tenant, code_black_member: "1")
    assert_response :redirect
    assert tenant.reload.code_black_member

    patch "/admin/tenants/#{tenant.id}", params: tenant_update_params(tenant, code_black_member: "0")
    assert_response :redirect
    assert_not tenant.reload.code_black_member

    logs = code_black_logs(tenant).order(:created_at).to_a
    assert_equal [ [ false, true ], [ true, false ] ], logs.map { |l| [ l.details["from"], l.details["to"] ] }
    assert(logs.all? { |l| l.actor_id == @uk.id })
  end

  test "TASK_115 S7 changing other fields does not write the membership audit" do
    tenant = create_hours_tenant!(code_black_member: true)

    patch "/admin/tenants/#{tenant.id}", params: tenant_update_params(tenant, name: "Новое имя", status: "frozen", code_black_member: "1")
    assert_response :redirect
    assert_equal "Новое имя", tenant.reload.name
    assert tenant.code_black_member, "S13: status change must not drop membership"
    assert_empty code_black_logs(tenant)
  end

  test "TASK_115 S7 rolled back update keeps flag and writes no audit" do
    tenant = create_hours_tenant!

    original = Platform::TenantOnboarding::Provision.method(:call)
    Platform::TenantOnboarding::Provision.define_singleton_method(:call) { |**| raise "provision failed" }
    begin
      patch "/admin/tenants/#{tenant.id}", params: tenant_update_params(tenant, code_black_member: "1")
    ensure
      Platform::TenantOnboarding::Provision.define_singleton_method(:call, original)
    end

    assert_response :unprocessable_entity
    assert_not tenant.reload.code_black_member
    assert_empty code_black_logs(tenant)
  end

  test "TASK_115 S9 tenants list shows the CODE:BLACK column" do
    create_tenant!(organization: @org, name: "В сети", slug: "cb-list-#{SecureRandom.hex(3)}", code_black_member: true)

    get "/admin/tenants"
    assert_response :success
    assert_match(/<th[^>]*>CODE:BLACK<\/th>/, response.body)
  end

  test "TASK_115 S10 non-UK roles cannot change the flag" do
    tenant = create_hours_tenant!

    %w[franchise_manager general_manager shift_manager barista].each do |code|
      user = create_user!(
        tenant: tenant,
        organization: @org,
        role_codes: [ code ],
        email: "#{code}-#{SecureRandom.hex(4)}@test.local",
        password: "pass123"
      )
      reset!
      login_as!(user)

      patch "/admin/tenants/#{tenant.id}", params: tenant_update_params(tenant, code_black_member: "1")
      assert_response :redirect, "role #{code}"
      assert_not tenant.reload.code_black_member, "role #{code} changed the flag"
    end
    assert_empty code_black_logs(tenant)
  end

  test "TASK_115 S11 production kitchen cannot join the network" do
    kitchen = create_tenant!(organization: @org, slug: "cb-kitchen-#{SecureRandom.hex(4)}", type: "production_kitchen")

    patch "/admin/tenants/#{kitchen.id}", params: tenant_update_params(kitchen, type: "production_kitchen", code_black_member: "1")

    assert_response :unprocessable_entity
    assert_not kitchen.reload.code_black_member
    assert_empty code_black_logs(kitchen)
  end

  private

  def code_black_logs(tenant)
    AdminAuditLog.where(action: "tenant_code_black_member_changed", entity_id: tenant.id)
  end

  def create_hours_tenant!(**attrs)
    tenant = create_tenant!(organization: @org, slug: "cb-#{SecureRandom.hex(4)}", **attrs)
    Platform::TenantWeekdaySchedulesSync.call(
      tenant: tenant,
      schedule_params: { "0" => { enabled: "1", opens_at: "09:00", closes_at: "21:00" } }
    )
    tenant
  end

  def tenant_update_params(tenant, **overrides)
    {
      tenant: {
        name: tenant.name,
        slug: tenant.slug,
        organization_id: @org.id,
        type: tenant.type,
        status: tenant.status,
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      }.merge(overrides),
      weekday_schedules: default_weekday_schedules
    }
  end

  def tenant_create_params(slug:, name: "Точка", weekday_schedules: default_weekday_schedules, modules: nil, point_campaign: nil, city: nil, code_black_member: nil)
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
    params[:tenant][:code_black_member] = code_black_member if code_black_member
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
