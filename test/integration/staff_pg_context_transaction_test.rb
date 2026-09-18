# frozen_string_literal: true

require "test_helper"

# TASK_93-G T-G1: staff SET LOCAL only inside open transaction (Shop API pattern).
class StaffPgContextTransactionTest < ActionDispatch::IntegrationTest
  include TestFactories

  self.use_transactional_tests = false

  setup do
    @tenant = create_tenant!(slug: "g1-staff-#{SecureRandom.hex(3)}")
    @barista = create_user!(
      tenant: @tenant,
      role_codes: %w[barista],
      email: "g1-barista-#{SecureRandom.hex(3)}@test.local"
    )
    @manager = create_user!(
      tenant: @tenant,
      role_codes: %w[general_manager],
      email: "g1-mgr-#{SecureRandom.hex(3)}@test.local"
    )
  end

  test "T-G1a barista includes WithTenantPgContext around_action wrap" do
    assert_includes Barista::BaseController.ancestors.map(&:to_s), "WithTenantPgContext",
                    "barista must include WithTenantPgContext (Shop-like txn wrap)"
  end

  test "T-G1b manager and prep include WithTenantPgContext" do
    assert_includes Manager::BaseController.ancestors.map(&:to_s), "WithTenantPgContext"
    assert_includes PrepKitchen::BaseController.ancestors.map(&:to_s), "WithTenantPgContext"
  end

  test "T-G1a barista request applies GUC readable inside request" do
    login_as!(@barista)
    get barista_dashboard_path
    assert_response :success
  end

  test "T-G1c set_pg_context without txn does not execute SET LOCAL" do
    fake = Object.new
    def fake.transaction_open? = false
    def fake.quote(v) = "'#{v.to_s.gsub("'", "''")}'"
    def fake.execute(sql)
      (@executed ||= []) << sql.to_s
    end
    def fake.executed = @executed || []

    original = ActiveRecord::Base.method(:connection)
    ActiveRecord::Base.define_singleton_method(:connection) { fake }
    begin
      ApplicationController.new.send(:set_pg_context, tenant_id: @tenant.id, user_id: @barista.id)
    ensure
      ActiveRecord::Base.define_singleton_method(:connection, original)
    end

    refute fake.executed.any? { |sql| sql.match?(/SET LOCAL app\.current_tenant_id/i) },
           "set_pg_context must no-op outside transaction (executed=#{fake.executed.inspect})"
  end
end
