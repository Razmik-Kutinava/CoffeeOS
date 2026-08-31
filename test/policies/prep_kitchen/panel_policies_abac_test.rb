# frozen_string_literal: true

require "test_helper"

class PrepKitchen::PanelPoliciesAbacTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @kitchen = create_tenant!(name: "Цех", slug: "pk-pol-#{SecureRandom.hex(3)}", type: "production_kitchen")
    @sales = create_tenant!(name: "Точка", slug: "pk-sp-#{SecureRandom.hex(3)}", type: "sales_point")
    FeatureFlag.create!(tenant: @kitchen, module: "prep_kitchen", enabled: true)
    @manager = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_manager], email: "pk-mgr@t.local")
    @worker = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_worker], email: "pk-wkr@t.local")
    @wrong_tenant_user = create_user!(tenant: @sales, role_codes: %w[prep_kitchen_manager], email: "wrong@t.local")
  end

  def ctx(user, tenant:)
    PolicyContext.build(user: user, tenant_id: tenant.id, shift: nil, tenant: tenant)
  end

  test "dashboard and queue readable by manager and worker" do
    manager_ctx = ctx(@manager, tenant: @kitchen)
    worker_ctx = ctx(@worker, tenant: @kitchen)

    assert PrepKitchen::DashboardPolicy.new(manager_ctx, :prep_kitchen_dashboard).show?
    assert PrepKitchen::DashboardPolicy.new(worker_ctx, :prep_kitchen_dashboard).show?
    assert PrepKitchen::QueuePolicy.new(manager_ctx, :prep_kitchen_queue).index?
    assert PrepKitchen::QueuePolicy.new(worker_ctx, :prep_kitchen_queue).index?
  end

  test "recipes reports and incidents are manager only" do
    manager_ctx = ctx(@manager, tenant: @kitchen)
    worker_ctx = ctx(@worker, tenant: @kitchen)

    assert PrepKitchen::RecipePolicy.new(manager_ctx, :prep_kitchen_recipe).index?
    assert PrepKitchen::ReportPolicy.new(manager_ctx, :prep_kitchen_report).index?
    assert PrepKitchen::IncidentPolicy.new(manager_ctx, :prep_kitchen_incident).index?

    assert_not PrepKitchen::RecipePolicy.new(worker_ctx, :prep_kitchen_recipe).index?
    assert_not PrepKitchen::ReportPolicy.new(worker_ctx, :prep_kitchen_report).index?
    assert_not PrepKitchen::IncidentPolicy.new(worker_ctx, :prep_kitchen_incident).index?
  end

  test "stop list index for staff update for manager only" do
    manager_ctx = ctx(@manager, tenant: @kitchen)
    worker_ctx = ctx(@worker, tenant: @kitchen)

    assert PrepKitchen::StopListPolicy.new(manager_ctx, :prep_kitchen_stop_list).index?
    assert PrepKitchen::StopListPolicy.new(worker_ctx, :prep_kitchen_stop_list).index?
    assert PrepKitchen::StopListPolicy.new(manager_ctx, :prep_kitchen_stop_list).update?
    assert_not PrepKitchen::StopListPolicy.new(worker_ctx, :prep_kitchen_stop_list).update?
  end

  test "sales_point tenant denied prep kitchen panel policies" do
    wrong_ctx = ctx(@wrong_tenant_user, tenant: @sales)

    assert_not PrepKitchen::DashboardPolicy.new(wrong_ctx, :prep_kitchen_dashboard).show?
    assert_not PrepKitchen::RecipePolicy.new(wrong_ctx, :prep_kitchen_recipe).index?
  end
end
