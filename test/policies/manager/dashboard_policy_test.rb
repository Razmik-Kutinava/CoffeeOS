# frozen_string_literal: true

require "test_helper"

class Manager::DashboardPolicyTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "mgr-dash-#{SecureRandom.hex(3)}")
    @shift = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "sm-dash@t.local")
    @gm = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "gm-dash@t.local")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "bar-dash@t.local")
  end

  def ctx(user, role_code:)
    PolicyContext.build(user: user, tenant_id: @tenant.id, role_code: role_code, shift: nil, tenant: @tenant)
  end

  test "shift and general managers can show dashboard" do
    assert Manager::DashboardPolicy.new(ctx(@shift, role_code: "shift_manager"), :manager_dashboard).show?
    assert Manager::DashboardPolicy.new(ctx(@gm, role_code: "general_manager"), :manager_dashboard).show?
  end

  test "barista cannot show manager dashboard" do
    assert_not Manager::DashboardPolicy.new(ctx(@barista, role_code: "barista"), :manager_dashboard).show?
  end
end
