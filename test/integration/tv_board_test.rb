require "test_helper"

class TvBoardTest < ActionDispatch::IntegrationTest
  # ERB часто рендерит атрибуты с переносами строк — матчим гибко.
  def assert_accepted_card!(body, position:, order_number:)
    assert_match(
      %r{data-status="accepted"[\s\S]*?data-queue-position="#{position}"[\s\S]*?<div class="tv-order-number">#{Regexp.escape(order_number)}</div>}m,
      body
    )
  end

  def create_tv_device!(tenant:, device_token:, tv_mode: Device::TV_MODE_ORDERS, last_seen_at: Time.current)
    Device.create!(
      tenant: tenant,
      device_type: "tv_board",
      name: "tv-#{SecureRandom.hex(4)}",
      device_token: device_token,
      is_active: true,
      last_seen_at: last_seen_at,
      token_expires_at: nil,
      registered_by: nil,
      metadata: { "tv_mode" => tv_mode }
    )
  end

  def create_tv_setting!(tenant:, show_order_count: 10, display_seconds_ready: 60, theme: "dark")
    TvBoardSetting.create!(
      tenant: tenant,
      show_order_count: show_order_count,
      display_seconds_ready: display_seconds_ready,
      theme: theme
    )
  end

  def create_order!(tenant:, status:, order_number:, created_at:)
    Order.create!(
      tenant: tenant,
      cash_shift: nil,
      order_number: order_number,
      source: "manual",
      status: status,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: created_at,
      updated_at: created_at
    )
  end

  test "tv_board: missing token -> forbidden" do
    create_tenant!(name: "T-TV", slug: "t-tv")
    get "/tv_board", params: {}
    assert_response :forbidden
  end

  test "tv_board: wrong token -> not found" do
    tenant = create_tenant!(name: "T-TV2", slug: "t-tv2")
    create_tv_setting!(tenant: tenant)

    get "/tv_board", params: { token: "wrong-token" }
    assert_response :not_found
  end

  test "tv_board renders 3 columns and correct queue indices (accepted)" do
    tenant = create_tenant!(name: "T-TV3", slug: "t-tv3")
    device = create_tv_device!(tenant: tenant, device_token: "tok-1", tv_mode: Device::TV_MODE_ORDERS)
    create_tv_setting!(tenant: tenant, show_order_count: 10)

    t1 = Time.current - 30.minutes
    t2 = Time.current - 20.minutes
    t3 = Time.current - 10.minutes

    create_order!(tenant: tenant, status: "accepted", order_number: "A1", created_at: t1)
    create_order!(tenant: tenant, status: "accepted", order_number: "A2", created_at: t2)
    create_order!(tenant: tenant, status: "accepted", order_number: "A3", created_at: t3)

    get "/tv_board", params: { token: device.device_token }
    assert_response :success

    assert_includes response.body, 'id="tv-orders-accepted"'
    assert_includes response.body, 'id="tv-orders-preparing"'
    assert_includes response.body, 'id="tv-orders-ready"'
    assert_includes response.body, "turbo-cable-stream-source"

    assert_accepted_card!(response.body, position: 1, order_number: "A1")
    assert_accepted_card!(response.body, position: 2, order_number: "A2")
    assert_accepted_card!(response.body, position: 3, order_number: "A3")
  end

  test "tv_board per-TV ads mode hides orders even when tenant limit > 0" do
    tenant = create_tenant!(name: "T-TV-ADS", slug: "t-tv-ads")
    device = create_tv_device!(tenant: tenant, device_token: "tok-ads", tv_mode: Device::TV_MODE_ADS)
    create_tv_setting!(tenant: tenant, show_order_count: 10)

    create_order!(tenant: tenant, status: "accepted", order_number: "HIDE-1", created_at: Time.current - 5.minutes)

    get "/tv_board", params: { token: device.device_token }
    assert_response :success

    assert_includes response.body, "ADS PLACEHOLDER"
    assert_no_match(/HIDE-1/, response.body)
    assert_includes response.body, %(data-tv-device-id="#{device.id}")
    assert_includes response.body, "turbo-cable-stream-source"
  end

  test "tv_board respects tenant show_order_count limit per column" do
    tenant = create_tenant!(name: "T-TV4", slug: "t-tv4")
    device = create_tv_device!(tenant: tenant, device_token: "tok-2", tv_mode: Device::TV_MODE_ORDERS)
    create_tv_setting!(tenant: tenant, show_order_count: 2)

    t1 = Time.current - 30.minutes
    t2 = Time.current - 20.minutes
    t3 = Time.current - 10.minutes

    create_order!(tenant: tenant, status: "accepted", order_number: "L1", created_at: t1)
    create_order!(tenant: tenant, status: "accepted", order_number: "L2", created_at: t2)
    create_order!(tenant: tenant, status: "accepted", order_number: "L3", created_at: t3)

    get "/tv_board", params: { token: device.device_token }
    assert_response :success

    assert_includes response.body, "L1"
    assert_includes response.body, "L2"
    assert_no_match(/L3/, response.body)
    assert_accepted_card!(response.body, position: 2, order_number: "L2")
    assert_no_match(/data-queue-position="3"/, response.body)
  end

  test "tv_board tenant show_order_count=0 shows ads for orders-mode TV too" do
    tenant = create_tenant!(name: "T-TV5", slug: "t-tv5")
    device = create_tv_device!(tenant: tenant, device_token: "tok-3", tv_mode: Device::TV_MODE_ORDERS)
    create_tv_setting!(tenant: tenant, show_order_count: 0)

    create_order!(tenant: tenant, status: "accepted", order_number: "OFF-1", created_at: Time.current - 5.minutes)

    get "/tv_board", params: { token: device.device_token }
    assert_response :success

    assert_includes response.body, "ADS PLACEHOLDER"
    assert_no_match(/OFF-1/, response.body)
  end
end
