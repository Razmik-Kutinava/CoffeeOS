# frozen_string_literal: true

require "test_helper"

class TenantOperatingHoursTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    seed_weekdays(mon_fri: [ "09:00", "21:00" ])
  end

  test "open_now during business hours" do
    travel_to utc_for_moscow("2026-06-15 12:00") do
      assert TenantOperatingHours.open_now?(@tenant)
      assert_nil TenantOperatingHours.next_open_at(@tenant)
    end
  end

  test "closed before opening same day returns morning open" do
    travel_to utc_for_moscow("2026-06-15 08:30") do
      assert_not TenantOperatingHours.open_now?(@tenant)
      next_at = TenantOperatingHours.next_open_at(@tenant)
      assert_equal "2026-06-15 09:00:00 +0300", next_at.to_s
    end
  end

  test "closed after hours returns next working day morning" do
    travel_to utc_for_moscow("2026-06-15 22:00") do
      assert_not TenantOperatingHours.open_now?(@tenant)
      next_at = TenantOperatingHours.next_open_at(@tenant)
      assert_equal "2026-06-16 09:00:00 +0300", next_at.to_s
    end
  end

  test "weekend skip to monday morning" do
    travel_to utc_for_moscow("2026-06-14 15:00") do
      assert_not TenantOperatingHours.open_now?(@tenant)
      next_at = TenantOperatingHours.next_open_at(@tenant)
      assert_equal "2026-06-15 09:00:00 +0300", next_at.to_s
    end
  end

  test "production kitchen always open" do
    @tenant.update_column(:type, "production_kitchen")

    travel_to utc_for_moscow("2026-06-14 03:00") do
      assert TenantOperatingHours.open_now?(@tenant)
      assert_nil TenantOperatingHours.next_open_at(@tenant)
    end
  end

  test "respects tenant timezone" do
    @tenant.update!(timezone: "Asia/Vladivostok")
    seed_weekdays(mon_fri: [ "10:00", "20:00" ])

    travel_to Time.utc(2026, 6, 15, 0, 30, 0) do
      assert TenantOperatingHours.open_now?(@tenant)
    end
  end

  # B1.11-BUG-OVERNIGHT: пн 09:23–01:24 (вт)
  test "overnight open during evening of schedule day" do
    seed_overnight_monday!

    travel_to utc_for_moscow("2026-06-15 23:00") do # пн
      assert TenantOperatingHours.open_now?(@tenant)
      assert_nil TenantOperatingHours.next_open_at(@tenant)
    end
  end

  test "overnight open after midnight before closes" do
    seed_overnight_monday!

    travel_to utc_for_moscow("2026-06-16 00:30") do # вт
      assert TenantOperatingHours.open_now?(@tenant)
    end
  end

  test "overnight closed after closes until next open" do
    seed_overnight_monday!

    travel_to utc_for_moscow("2026-06-16 02:00") do # вт после 01:24
      assert_not TenantOperatingHours.open_now?(@tenant)
      next_at = TenantOperatingHours.next_open_at(@tenant)
      assert_equal "2026-06-22 09:23:00 +0300", next_at.to_s # след. пн
    end
  end

  test "overnight closed before opens same day" do
    seed_overnight_monday!

    travel_to utc_for_moscow("2026-06-15 08:00") do # пн до 09:23
      assert_not TenantOperatingHours.open_now?(@tenant)
      next_at = TenantOperatingHours.next_open_at(@tenant)
      assert_equal "2026-06-15 09:23:00 +0300", next_at.to_s
    end
  end

  private

  def seed_overnight_monday!
    @tenant.weekday_schedules.delete_all
    TenantWeekdaySchedule.create!(
      tenant: @tenant,
      weekday: 0,
      enabled: true,
      opens_at: "09:23",
      closes_at: "01:24"
    )
    (1..6).each do |wd|
      TenantWeekdaySchedule.create!(tenant: @tenant, weekday: wd, enabled: false)
    end
    @tenant.weekday_schedules.reset
  end


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
    @tenant.weekday_schedules.reset
  end

  def utc_for_moscow(local_time)
    Time.find_zone("Europe/Moscow").parse(local_time).utc
  end
end
