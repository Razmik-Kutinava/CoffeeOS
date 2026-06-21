# frozen_string_literal: true

require "test_helper"

class Shop::Api::B111OperatingHoursTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    seed_weekdays(mon_fri: ["09:00", "21:00"])
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @customer = create_mobile_customer!(email: "b111-hours@example.com")
    @email = @customer.email
  end

  test "GET config exposes operating_hours when open" do
    travel_to moscow("2026-06-15 12:00") do
      get "/shop/api/config", headers: shop_tenant_headers(@tenant.id)
      assert_response :success
      hours = response.parsed_body["operating_hours"]
      assert_equal true, hours["is_open"]
      assert_nil hours["closed_until"]
      assert_nil hours["closed_message"]
      assert_equal "Пн–Пт 09:00–21:00", hours["schedule_display"]
    end
  end

  test "GET config exposes closed_until when closed" do
    travel_to moscow("2026-06-15 22:00") do
      get "/shop/api/config", headers: shop_tenant_headers(@tenant.id)
      assert_response :success
      hours = response.parsed_body["operating_hours"]
      assert_equal false, hours["is_open"]
      assert hours["closed_until"].present?
      assert_includes hours["closed_message"], "09:00"
    end
  end

  test "GET categories meta includes operating_hours" do
    travel_to moscow("2026-06-14 15:00") do
      get "/shop/api/categories", headers: shop_tenant_headers(@tenant.id)
      assert_response :success
      hours = response.parsed_body.dig("meta", "operating_hours")
      assert_equal false, hours["is_open"]
      assert_includes hours["closed_message"], "09:00"
    end
  end

  test "POST cart add works when tenant closed" do
    travel_to moscow("2026-06-14 15:00") do
      post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_response :success
    end
  end

  test "legacy tenant without schedule stays open" do
    @tenant.weekday_schedules.delete_all

    travel_to moscow("2026-06-14 15:00") do
      get "/shop/api/config", headers: shop_tenant_headers(@tenant.id)
      assert_equal true, response.parsed_body.dig("operating_hours", "is_open")
      assert_nil response.parsed_body.dig("operating_hours", "schedule_display")
    end
  end

  test "POST orders rejected when tenant closed" do
    travel_to moscow("2026-06-14 15:00") do
      post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_response :success

      verify_shop_email!(tenant_id: @tenant.id, email: @email)

      post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, payment_method: "cash"),
        as: :json
      assert_response :unprocessable_entity
      body = response.parsed_body
      assert_equal false, body["is_open"]
      assert body["closed_until"].present?
      assert_includes body["error"], "закрыты"
      assert_equal 0, Order.where(tenant_id: @tenant.id, source: :mobile).count
    end
  end

  test "POST orders allowed when tenant open" do
    travel_to moscow("2026-06-15 12:00") do
      post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_response :success

      verify_shop_email!(tenant_id: @tenant.id, email: @email)

      post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, payment_method: "cash"),
        as: :json
      assert_response :success
      assert response.parsed_body["order_id"].present?
    end
  end

  private

  def seed_weekdays(mon_fri:)
    @tenant.weekday_schedules.delete_all
    (0..4).each do |wd|
      TenantWeekdaySchedule.create!(
        tenant: @tenant,
        weekday: wd,
        enabled: true,
        opens_at: mon_fri[0],
        closes_at: mon_fri[1]
      )
    end
    (5..6).each do |wd|
      TenantWeekdaySchedule.create!(tenant: @tenant, weekday: wd, enabled: false)
    end
  end

  def moscow(local_time)
    Time.find_zone("Europe/Moscow").parse(local_time).utc
  end
end
