# frozen_string_literal: true

require "test_helper"

class AbacFullEnforcementTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "abac-fe-bar@t.local")
    @shift_manager = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "abac-fe-sm@t.local")
    @open_shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    @other_shift = CashShift.create!(
      tenant: @tenant,
      status: "closed",
      opened_by: @barista,
      opened_at: 3.days.ago,
      opening_cash: 0,
      closed_at: 2.days.ago,
      closing_cash: 0,
      closed_by: @barista
    )
  end

  def ctx(user, shift: :auto, module_flags: nil)
    PolicyContext.build(
      user: user,
      tenant_id: @tenant.id,
      shift: shift,
      tenant: @tenant,
      module_flags: module_flags
    )
  end

  test "ABAC-011 barista module disabled denies order create" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift, module_flags: { barista: false }), Order)
    assert_not policy.create?
  end

  test "ABAC-019 read_board allowed for barista with module" do
    policy = OrderPolicy.new(ctx(@barista, shift: nil, module_flags: { barista: true }), Order)
    assert policy.read_board?
  end

  test "ABAC-022 shift_manager cannot close foreign shift" do
    policy = CashShiftPolicy.new(ctx(@shift_manager, shift: @open_shift), @other_shift)
    assert_not policy.close?
  end

  test "ABAC-022 shift_manager can close current open shift" do
    policy = CashShiftPolicy.new(ctx(@shift_manager, shift: @open_shift), @open_shift)
    assert policy.close?
  end

  test "ABAC-033 payment scope limits shift_manager to current shift" do
    order_in = Order.create!(
      tenant: @tenant,
      cash_shift: @open_shift,
      order_number: "PAY-IN-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    order_out = Order.create!(
      tenant: @tenant,
      cash_shift: @other_shift,
      order_number: "PAY-OUT-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    pay_in = Payment.create!(tenant: @tenant, order: order_in, amount: 100, method: "cash", provider: "manual", status: "succeeded")
    Payment.create!(tenant: @tenant, order: order_out, amount: 100, method: "cash", provider: "manual", status: "succeeded")

    Current.tenant_id = @tenant.id
    scope = Finance::PaymentPolicy::Scope.new(ctx(@shift_manager, shift: @open_shift), Payment.all).resolve
    assert_equal [ pay_in.id ], scope.pluck(:id)
  ensure
    Current.tenant_id = nil
  end

  test "ABAC-015 tenant_open? false outside schedule" do
    seed_weekdays_closed_weekend!
    travel_to moscow("2026-06-14 15:00") do
      context = PolicyContext.build(user: @barista, tenant_id: @tenant.id, shift: @open_shift, tenant: @tenant)
      assert_not context.tenant_open?
      assert_not TenantOperatingHoursEnforcement.accepting_online_orders?(@tenant)
    end
  end

  test "ABAC-015 barista POS create allowed outside online hours when shift open" do
    seed_weekdays_closed_weekend!
    travel_to moscow("2026-06-14 15:00") do
      policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), Order)
      assert policy.create?, "barista POS exempt from ABAC-015 online-hours guard"
    end
  end

  test "ABAC-007 blog editor policy" do
    editor = create_user!(tenant: @tenant, role_codes: %w[blog_editor], email: "editor@t.local")
    reader = create_user!(tenant: @tenant, role_codes: %w[barista], email: "reader@t.local")

    assert Blog::PostPolicy.new(editor, BlogPost).create?
    assert_not Blog::PostPolicy.new(reader, BlogPost).create?
  end

  test "ABAC-056 kiosk device auth requires module when flag present" do
    device = Device.create!(
      tenant: @tenant,
      device_type: "kiosk",
      name: "K1",
      device_token: SecureRandom.hex(16),
      is_active: true
    )
    TenantModuleFlags.sync!(@tenant, { "kiosk" => "0" })

    auth = Devices::DeviceAuthPolicy.new(token: device.device_token, device_type: "kiosk")
    assert_not auth.authenticate?
  end

  test "ABAC-057 tv board policy accepts valid token" do
    device = Device.create!(
      tenant: @tenant,
      device_type: "tv_board",
      name: "TV",
      device_token: SecureRandom.hex(16),
      is_active: true
    )

    policy = TvBoardPolicy.new(token: device.device_token)
    assert policy.show?
    assert_equal device.id, policy.device.id
  end

  private

  def seed_weekdays_closed_weekend!
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
