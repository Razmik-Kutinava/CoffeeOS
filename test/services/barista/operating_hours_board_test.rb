# frozen_string_literal: true

require "test_helper"

class Barista::OperatingHoursBoardTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    seed_weekdays
  end

  test "no conflict when tenant open" do
    travel_to moscow("2026-06-15 12:00") do
      ctx = Barista::OperatingHoursBoard.context(tenant: @tenant, shift: @shift)
      assert_not ctx[:schedule_conflict]
      assert_nil ctx[:conflict_message]
      assert ctx[:tenant_open]
    end
  end

  test "conflict when shift open and schedule closed" do
    travel_to moscow("2026-06-14 15:00") do
      ctx = Barista::OperatingHoursBoard.context(tenant: @tenant, shift: @shift)
      assert ctx[:schedule_conflict]
      assert_includes ctx[:conflict_message], "Смена открыта"
      assert_not ctx[:tenant_open]
    end
  end

  test "no conflict when shift closed" do
    travel_to moscow("2026-06-14 15:00") do
      ctx = Barista::OperatingHoursBoard.context(tenant: @tenant, shift: nil)
      assert_not ctx[:schedule_conflict]
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
