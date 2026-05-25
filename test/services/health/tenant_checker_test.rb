# frozen_string_literal: true

require "test_helper"

class Health::TenantCheckerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Health Point", slug: "health-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant, role_codes: %w[barista], email: "health-barista@test.local")
  end

  test "returns checks hash and overall status" do
    result = Health::TenantChecker.new(@tenant).call

    assert_equal @tenant.id, result[:tenant_id]
    %i[cash_register orders queue kiosk app_mobile payments inventory failed_payments].each do |key|
      assert result[:checks].key?(key), "missing check #{key}"
      assert %w[ok warning error].include?(result[:checks][key][:status])
    end
    assert %w[ok warning error].include?(result[:overall])
  end

  test "warns when no open cash shift" do
    result = Health::TenantChecker.new(@tenant).call

    assert_equal "warning", result[:checks][:cash_register][:status]
    assert_includes result[:checks][:cash_register][:message], "касс"
  end

  test "ok cash register when shift is open" do
    open_cash_shift!(tenant: @tenant, opened_by: @user)

    result = Health::TenantChecker.new(@tenant).call

    assert_equal "ok", result[:checks][:cash_register][:status]
  end
end
