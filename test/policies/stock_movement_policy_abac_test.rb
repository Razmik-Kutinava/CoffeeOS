# frozen_string_literal: true

require "test_helper"

class StockMovementPolicyAbacTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @kitchen = create_tenant!(name: "Цех", slug: "kitchen-#{SecureRandom.hex(3)}", type: "production_kitchen")
    @sales = create_tenant!(name: "Точка", slug: "sales-#{SecureRandom.hex(3)}", type: "sales_point")
    FeatureFlag.create!(tenant: @kitchen, module: "prep_kitchen", enabled: true)
    @manager = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_manager], email: "prep-mgr@t.local")
    @worker = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_worker], email: "prep-wkr@t.local")
    @wrong_tenant_user = create_user!(tenant: @sales, role_codes: %w[prep_kitchen_manager], email: "wrong@t.local")
  end

  def ctx(user, tenant:)
    PolicyContext.build(user: user, tenant_id: tenant.id, shift: nil, tenant: tenant)
  end

  test "prep manager on production_kitchen can create movement" do
    policy = StockMovementPolicy.new(ctx(@manager, tenant: @kitchen), StockMovement)
    assert policy.create?
  end

  test "prep worker cannot create movement" do
    policy = StockMovementPolicy.new(ctx(@worker, tenant: @kitchen), StockMovement)
    assert_not policy.create?
  end

  test "prep manager on sales_point tenant denied" do
    policy = StockMovementPolicy.new(ctx(@wrong_tenant_user, tenant: @sales), StockMovement)
    assert_not policy.create?
    assert_not policy.index?
  end

  test "prep worker can index on production_kitchen" do
    policy = StockMovementPolicy.new(ctx(@worker, tenant: @kitchen), StockMovement)
    assert policy.index?
  end
end
