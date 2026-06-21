# frozen_string_literal: true

require "test_helper"

class Shop::OperatingHoursScheduleTextTest < ActiveSupport::TestCase
  include TestFactories

  test "formats grouped weekdays for header" do
    tenant = create_tenant!
    seed_schedule(tenant, mon_fri: %w[09:00 21:00], sat: %w[10:00 18:00])

    text = Shop::OperatingHoursScheduleText.for(tenant)

    assert_equal "Пн–Пт 09:00–21:00, Сб 10:00–18:00", text
  end

  test "returns nil when no enabled days" do
    tenant = create_tenant!

    assert_nil Shop::OperatingHoursScheduleText.for(tenant)
  end

  test "included in shop operating hours json" do
    tenant = create_tenant!
    seed_schedule(tenant, mon_fri: %w[08:00 20:00])

    json = Shop::OperatingHours.for(tenant).client_json

    assert_equal "Пн–Пт 08:00–20:00", json[:schedule_display]
  end

  private

  def seed_schedule(tenant, mon_fri:, sat: nil)
    tenant.weekday_schedules.delete_all
    (0..4).each do |wd|
      TenantWeekdaySchedule.create!(
        tenant: tenant, weekday: wd, enabled: true,
        opens_at: mon_fri[0], closes_at: mon_fri[1]
      )
    end
    if sat
      TenantWeekdaySchedule.create!(
        tenant: tenant, weekday: 5, enabled: true,
        opens_at: sat[0], closes_at: sat[1]
      )
      TenantWeekdaySchedule.create!(tenant: tenant, weekday: 6, enabled: false)
    else
      (5..6).each { |wd| TenantWeekdaySchedule.create!(tenant: tenant, weekday: wd, enabled: false) }
    end
  end
end
