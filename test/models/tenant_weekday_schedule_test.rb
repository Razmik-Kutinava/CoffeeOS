# frozen_string_literal: true

require "test_helper"

class TenantWeekdayScheduleTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
  end

  test "creates enabled weekday with open and close times" do
    row = TenantWeekdaySchedule.create!(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:monday],
      enabled: true,
      opens_at: "09:00",
      closes_at: "21:00"
    )

    assert row.persisted?
    assert_equal "Понедельник", row.weekday_name
  end

  test "disabled day does not require hours" do
    row = TenantWeekdaySchedule.create!(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:sunday],
      enabled: false
    )

    assert row.valid?
    assert_nil row.opens_at
    assert_nil row.closes_at
  end

  test "enabled day requires hours" do
    row = TenantWeekdaySchedule.new(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:friday],
      enabled: true
    )

    assert_not row.valid?
    assert_includes row.errors[:opens_at], "can't be blank"
    assert_includes row.errors[:closes_at], "can't be blank"
  end

  test "closes_at must be after opens_at on same day" do
    row = TenantWeekdaySchedule.new(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:tuesday],
      enabled: true,
      opens_at: "18:00",
      closes_at: "09:00"
    )

    assert_not row.valid?
    assert_includes row.errors[:closes_at], "must be after opens_at"
  end

  test "unique weekday per tenant" do
    TenantWeekdaySchedule.create!(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:wednesday],
      enabled: true,
      opens_at: "10:00",
      closes_at: "20:00"
    )

    dup = TenantWeekdaySchedule.new(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:wednesday],
      enabled: true,
      opens_at: "11:00",
      closes_at: "19:00"
    )

    assert_not dup.valid?
    assert_includes dup.errors[:weekday], "has already been taken"
  end

  test "tenant has_many weekday_schedules" do
    TenantWeekdaySchedule.create!(
      tenant: @tenant,
      weekday: TenantWeekdaySchedule::WEEKDAYS[:monday],
      enabled: true,
      opens_at: "08:00",
      closes_at: "22:00"
    )

    assert_equal 1, @tenant.weekday_schedules.reload.count
  end
end
