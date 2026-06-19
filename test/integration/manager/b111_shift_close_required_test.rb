# frozen_string_literal: true

require "test_helper"

class Manager::B111ShiftCloseRequiredTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    Rack::Attack.enabled = false if defined?(Rack::Attack)
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    @manager = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "b111-mgr-#{SecureRandom.hex(3)}@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    seed_weekdays
  end

  test "manager sees close required alert on schedule conflict" do
    travel_to moscow("2026-06-14 15:00") do
      login_as!(@manager)
      get manager_shifts_path
      assert_response :success
      assert_includes response.body, "manager-shift-close-required"
      assert_includes response.body, "Требуется закрытие смены"
    end
  end

  test "manager sees close required after barista logout note" do
    travel_to moscow("2026-06-15 12:00") do
      @shift.update!(note: "#{CashShift::SCHEDULE_CLOSE_NOTE_TAG} test] бариста вышел")
      login_as!(@manager)
      get manager_shift_path(@shift)
      assert_response :success
      assert_includes response.body, "manager-shift-close-required"
      assert_includes response.body, "Бариста вышел"
    end
  end

  test "no alert when shift closed" do
    @shift.close!(@barista, 0)
    login_as!(@manager)
    get manager_shifts_path
    assert_response :success
    assert_not_includes response.body, "manager-shift-close-required"
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
