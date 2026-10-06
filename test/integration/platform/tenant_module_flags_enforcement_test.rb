# frozen_string_literal: true

require "test_helper"

# Галочки модулей УК: ТВ-борд / меню / QR-офферы реально выключают функции точки.
class Platform::TenantModuleFlagsEnforcementTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @tenant = create_tenant!
    @manager = create_user!(
      tenant: @tenant,
      role_codes: %w[general_manager],
      email: "gm-flags-#{SecureRandom.hex(3)}@test.local"
    )
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  def disable_module!(mod)
    FeatureFlag.find_or_initialize_by(tenant_id: @tenant.id, module: mod).update!(enabled: false)
  end

  def create_tv!
    Device.create!(
      tenant: @tenant,
      device_type: "tv_board",
      name: "tv-#{SecureRandom.hex(3)}",
      device_token: SecureRandom.hex(8),
      is_active: true,
      metadata: { "tv_mode" => Device::TV_MODE_ORDERS }
    )
  end

  test "tv_board off: tv screen shows module disabled instead of board" do
    device = create_tv!
    disable_module!("tv_board")

    get "/tv_board", params: { token: device.device_token }

    assert_response :forbidden
    assert_includes response.body, "TV-борд отключён"
  end

  test "tv_board on: tv screen works" do
    device = create_tv!

    get "/tv_board", params: { token: device.device_token }

    assert_response :success
  end

  test "tv_board off: manager cannot create tv and sidebar hides tv links" do
    disable_module!("tv_board")
    login_as!(@manager)

    assert_no_difference -> { Device.where(tenant_id: @tenant.id, device_type: "tv_board").count } do
      post manager_devices_path, params: { device: { name: "Зал" } }
    end
    assert_redirected_to manager_dashboard_path

    get manager_tv_board_settings_path
    assert_redirected_to manager_dashboard_path

    get manager_dashboard_path
    assert_not_includes response.body, manager_tv_board_settings_path
  end

  test "menu off: manager cannot open point menu and sidebar hides it" do
    disable_module!("menu")
    login_as!(@manager)

    get manager_menu_path
    assert_redirected_to manager_dashboard_path

    get manager_dashboard_path
    assert_not_includes response.body, %(href="#{manager_menu_path}")
  end

  test "menu on: manager opens point menu" do
    login_as!(@manager)

    get manager_menu_path

    assert_response :success
  end

  test "qr_offers off: subscription offer funnel is forbidden" do
    disable_module!("qr_offers")
    login_as!(@manager)

    get manager_subscription_offer_funnel_path

    assert_response :forbidden
  end

  test "qr_offers off: offer presentation hides banner, push and unread" do
    customer = create_mobile_customer!(email: "flags-#{SecureRandom.hex(3)}@example.com")
    service = Subscriptions::OfferPresentationService.new(customer: customer, point: @tenant)
    service.define_singleton_method(:banner?) { |_state| true }
    service.define_singleton_method(:unread?) { |_state| true }

    assert_equal true, service.call[:should_show_banner]

    disable_module!("qr_offers")

    assert_equal(
      { should_show_banner: false, should_show_push: false, has_unread_offer_in_lk: false },
      service.call
    )
  end
end
