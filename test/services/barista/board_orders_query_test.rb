# frozen_string_literal: true

require "test_helper"

class Barista::BoardOrdersQueryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "FIFO", slug: "fifo-tenant")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "fifo-barista@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
  end

  test "for_column returns orders FIFO by created_at asc" do
    newer = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "FIFO-NEW",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: 1.hour.ago
    )
    older = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "FIFO-OLD",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: 3.hours.ago
    )

    ids = Barista::BoardOrdersQuery.for_column(tenant_id: @tenant.id, status: "accepted").map(&:id)
    assert_equal [older.id, newer.id], ids
  end

  test "column_dom_id maps board statuses" do
    assert_equal "orders-new", Barista::BoardOrdersQuery.column_dom_id("accepted")
    assert_equal "orders-preparing", Barista::BoardOrdersQuery.column_dom_id("preparing")
    assert_equal "orders-ready", Barista::BoardOrdersQuery.column_dom_id("ready")
    assert_nil Barista::BoardOrdersQuery.column_dom_id("issued")
  end

  test "board_scope includes current shift and vitrina since shift opened" do
    in_shift = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "SHIFT-1",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100
    )
    vitrina = Order.create!(
      tenant: @tenant, cash_shift: nil, order_number: "VIT-1",
      source: "mobile", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: @shift.opened_at + 1.minute
    )

    ids = Barista::BoardOrdersQuery.board_scope(tenant_id: @tenant.id).pluck(:id)
    assert_includes ids, in_shift.id
    assert_includes ids, vitrina.id
  end

  test "board_scope excludes vitrina orders created before current shift opened" do
    stale_vitrina = Order.create!(
      tenant: @tenant, cash_shift: nil, order_number: "STALE-VIT",
      source: "mobile", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: @shift.opened_at - 1.hour
    )

    ids = Barista::BoardOrdersQuery.board_scope(tenant_id: @tenant.id).pluck(:id)
    assert_not_includes ids, stale_vitrina.id
  end

  test "for_column returns more than 50 accepted in current shift" do
    55.times do |i|
      Order.create!(
        tenant: @tenant, cash_shift: @shift, order_number: "BULK-#{i}",
        source: "manual", status: "accepted",
        total_amount: 100, discount_amount: 0, final_amount: 100,
        created_at: @shift.opened_at + i.seconds
      )
    end
    newest = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "BULK-NEW",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: @shift.opened_at + 100.seconds
    )

    ids = Barista::BoardOrdersQuery.for_column(tenant_id: @tenant.id, status: "accepted").map(&:id)
    assert_equal 56, ids.size
    assert_includes ids, newest.id
  end
end
