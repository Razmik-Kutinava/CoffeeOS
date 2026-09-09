# frozen_string_literal: true

require "test_helper"

class Rls::JobTenantContextTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "job-guc-#{SecureRandom.hex(3)}")
    @order = Order.create!(
      tenant_id: @tenant.id,
      order_number: "JG-#{SecureRandom.hex(2)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    Current.reset
  end

  teardown do
    Current.reset
  end

  test "with nil record raises" do
    assert_raises(ArgumentError) do
      Rls::JobTenantContext.with(nil) { }
    end
  end

  test "with blank tenant_id raises" do
    record = Struct.new(:tenant_id).new(nil)
    assert_raises(ArgumentError) do
      Rls::JobTenantContext.with(record) { }
    end
  end

  test "with order sets Current.tenant_id and GUC inside block then resets" do
    inside_current = nil
    inside_guc = nil

    Rls::JobTenantContext.with(@order) do
      inside_current = Current.tenant_id
      inside_guc = read_tenant_guc
    end

    assert_equal @tenant.id, inside_current
    assert_guc_matches_tenant!(inside_guc, @tenant.id)
    assert_nil Current.tenant_id
  end

  test "with_tenant_id sets GUC from id" do
    seen = nil
    Rls::JobTenantContext.with_tenant_id(@tenant.id) do
      seen = Current.tenant_id
    end
    assert_equal @tenant.id, seen
    assert_nil Current.tenant_id
  end

  private

  def read_tenant_guc
    conn = ActiveRecord::Base.connection
    conn.select_value("SHOW app.current_tenant_id")
  rescue ActiveRecord::StatementInvalid => e
    return :guc_unsupported if e.message.include?("unrecognized configuration parameter")

    raise
  end

  def assert_guc_matches_tenant!(guc_value, tenant_id)
    return if guc_value == :guc_unsupported

    assert_equal tenant_id.to_s, guc_value.to_s
  end
end
