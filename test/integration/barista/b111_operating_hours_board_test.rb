# frozen_string_literal: true

require "test_helper"

class Barista::B111OperatingHoursBoardTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    Rack::Attack.enabled = false if defined?(Rack::Attack)
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    @category = create_category!
    @product = create_product!(category: @category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 150)
    seed_weekdays
  end

  test "dashboard empty when shift closed" do
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "POS-1",
      source: "manual", status: "accepted",
      total_amount: 150, discount_amount: 0, final_amount: 150
    )
    @shift.close!(@barista, 0)

    login_as!(@barista)
    get barista_dashboard_path
    assert_response :success
    assert_includes response.body, 'id="barista-board-slots"'
    assert_not_includes response.body, "POS-1"
  end

  test "dashboard shows conflict banner when shift open outside schedule" do
    travel_to moscow("2026-06-14 15:00") do
      open_cash_shift!(tenant: @tenant, opened_by: @barista)
      login_as!(@barista)
      get barista_dashboard_path
      assert_response :success
      assert_includes response.body, "barista-schedule-conflict-banner"
      assert_includes response.body, "вне режима работы"
    end
  end

  test "POS order created outside schedule when shift open" do
    travel_to moscow("2026-06-14 15:00") do
      open_cash_shift!(tenant: @tenant, opened_by: @barista)
      login_as!(@barista)

      post barista_orders_path, params: {
        cart_items: [{ product_id: @product.id, quantity: 1, selected_modifiers: [] }],
        payment_method: "cash"
      }

      assert_redirected_to barista_dashboard_path
      order = Order.where(tenant_id: @tenant.id, source: "manual").order(created_at: :desc).first
      assert order
      assert_equal "accepted", order.status
    end
  end

  test "logout during conflict stamps shift note" do
    travel_to moscow("2026-06-14 15:00") do
      shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
      login_as!(@barista)

      delete logout_path
      assert_redirected_to login_path
      assert_includes shift.reload.note.to_s, "[B1.11"
    end
  end

  private

  def seed_weekdays
    @tenant.weekday_schedules.delete_all
    (0..4).each do |wd|
      TenantWeekdaySchedule.create!(
        tenant: @tenant, weekday: wd, enabled: true, opens_at: "09:00", closes_at: "21:00"
      )
    end
    (5..6).each { |wd| TenantWeekdaySchedule.create!(tenant: @tenant, weekday: wd, enabled: false) }
  end

  def moscow(local_time)
    Time.find_zone("Europe/Moscow").parse(local_time).utc
  end
end
