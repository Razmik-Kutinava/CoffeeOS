# frozen_string_literal: true

require "test_helper"

class Platform::TenantWeekdaySchedulesSyncTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
  end

  test "saves enabled weekdays from params" do
    ok = Platform::TenantWeekdaySchedulesSync.call(
      tenant: @tenant,
      schedule_params: weekday_params(mon: ["09:00", "21:00"], wed: ["10:00", "20:00"])
    )

    assert ok
    rows = @tenant.weekday_schedules.order(:weekday)
    assert_equal 2, rows.enabled.count
    assert_equal "09:00", rows.find_by(weekday: 0).opens_at.strftime("%H:%M")
  end

  test "fails when no day enabled for sales point" do
    ok = Platform::TenantWeekdaySchedulesSync.call(
      tenant: @tenant,
      schedule_params: {}
    )

    assert_not ok
    assert_includes @tenant.errors[:base].first, "хотя бы один день"
  end

  test "skips validation for production kitchen" do
    kitchen = create_tenant!(slug: "pk-#{SecureRandom.hex(3)}", name: "Цех")
    kitchen.update_column(:type, "production_kitchen")

    ok = Platform::TenantWeekdaySchedulesSync.call(tenant: kitchen, schedule_params: {})

    assert ok
    assert_empty kitchen.weekday_schedules
  end

  private

  def weekday_params(**days)
    mapping = {
      mon: 0, tue: 1, wed: 2, thu: 3, fri: 4, sat: 5, sun: 6
    }
    days.each_with_object({}) do |(key, (opens, closes)), h|
      wd = mapping.fetch(key)
      h[wd] = { enabled: "1", opens_at: opens, closes_at: closes }
    end
  end
end
