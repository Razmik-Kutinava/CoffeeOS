# frozen_string_literal: true

require "test_helper"

class CashShiftScheduleCloseTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    seed_weekdays
  end

  test "requires_manager_close on schedule conflict" do
    travel_to moscow("2026-06-14 15:00") do
      assert @shift.requires_manager_close?(@tenant)
    end
  end

  test "requires_manager_close when note tagged" do
    @shift.update!(note: "#{CashShift::SCHEDULE_CLOSE_NOTE_TAG} logout")
    assert @shift.requires_manager_close?(@tenant)
  end

  test "no requirement when open during schedule" do
    travel_to moscow("2026-06-15 12:00") do
      assert_not @shift.requires_manager_close?(@tenant)
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
