# frozen_string_literal: true

require "test_helper"

# TASK_93-G T-G6: ensure_tenant_id raise policy (R6).
class ApplicationRecordEnsureTenantTest < ActiveSupport::TestCase
  include TestFactories

  class EnsureProbe < ApplicationRecord
    self.table_name = "orders"
  end

  test "T-G6a production-like blank tenant_id raises" do
    probe = EnsureProbe.new(
      order_number: "G6-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "pending_payment",
      total_amount: 1,
      discount_amount: 0,
      final_amount: 1
    )
    probe.tenant_id = nil

    env = Rails.env
    Rails.env = ActiveSupport::StringInquirer.new("production")
    begin
      assert_raises(RuntimeError) { probe.send(:ensure_tenant_id) }
    ensure
      Rails.env = env
    end
  end

  test "T-G6b development blank tenant_id raises (production-like)" do
    probe = EnsureProbe.new
    probe.tenant_id = nil

    env = Rails.env
    Rails.env = ActiveSupport::StringInquirer.new("development")
    begin
      assert_raises(RuntimeError) { probe.send(:ensure_tenant_id) }
    ensure
      Rails.env = env
    end
  end

  test "T-G6b test env allows blank with warn" do
    probe = EnsureProbe.new
    probe.tenant_id = nil

    assert_nothing_raised { probe.send(:ensure_tenant_id) }
  end
end
