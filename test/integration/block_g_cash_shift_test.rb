# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок G: гибрид смены — shop без смены, бариста POS только с открытой сменой; отмена с причиной + audit.
class BlockGCashShiftTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "bg-#{SecureRandom.hex(3)}")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "bg-b@#{SecureRandom.hex(4)}.test")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    category = create_category!
    @product = create_product!(category: category, name: "BG Coffee")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
  end

  test "shop order succeeds without cash shift" do
    headers = { "X-Shop-Tenant" => @tenant.id.to_s }
    email = "bg-shop-#{SecureRandom.hex(4)}@test.local"
    post "/shop/api/cart/add",
      headers: headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: email)

    post "/shop/api/orders",
      headers: headers,
      params: { email: email, name: "BG Shop", payment_method: "card" },
      as: :json
    assert_response :success

    order = Order.find(response.parsed_body["order_id"])
    assert_nil order.cash_shift_id
  end

  test "barista order requires open shift and sets cash_shift_id" do
    login_as!(@barista)
    post "/barista/orders", params: {
      cart_items: [ { product_id: @product.id, quantity: 1 } ],
      payment_method: "cash"
    }
    assert_response :redirect

    order = Order.where(tenant: @tenant).order(created_at: :desc).first
    assert_equal @shift.id, order.cash_shift_id
    assert_equal "accepted", order.status
  end

  test "barista order from HTML form cart_items index keys" do
    login_as!(@barista)
    post "/barista/orders", params: {
      cart_items: { "0" => { product_id: @product.id, quantity: 1 } },
      payment_method: "cash"
    }
    assert_response :redirect

    order = Order.where(tenant: @tenant).order(created_at: :desc).first
    assert_equal @shift.id, order.cash_shift_id
  end

  test "barista cannot create order when shift closed" do
    @shift.update!(status: "closed", closed_at: Time.current, closed_by: @barista, closing_cash: 0)
    login_as!(@barista)
    before = Order.where(tenant: @tenant).count

    post "/barista/orders", params: {
      cart_items: [ { product_id: @product.id, quantity: 1 } ],
      payment_method: "cash"
    }

    assert_redirected_to barista_new_order_path
    assert_equal before, Order.where(tenant: @tenant).count
    assert_match(/смена не открыта/i, flash[:alert].to_s)
  end

  test "barista cannot update order status without open shift" do
    order = Order.create!(
      tenant: @tenant,
      cash_shift: @shift,
      order_number: "BG-1",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    @shift.update!(status: "closed", closed_at: Time.current, closed_by: @barista, closing_cash: 0)

    login_as!(@barista)
    patch "/barista/orders/#{order.id}/update_status", params: { status: "preparing" }

    assert_response :redirect
    assert_equal "accepted", order.reload.status
    assert_match(/смена не открыта/i, flash[:alert].to_s)
  end

  test "cancel without reason is rejected" do
    login_as!(@barista)
    order = Order.create!(
      tenant: @tenant,
      cash_shift: @shift,
      order_number: "BG-C1",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    assert_no_difference "AdminAuditLog.count" do
      post "/barista/orders/#{order.id}/cancel", params: { reason: "" }
    end

    assert_redirected_to barista_dashboard_path
    assert_equal "accepted", order.reload.status
    assert_match(/причин/i, flash[:alert].to_s)
  end

  test "cancel with reason writes admin audit log" do
    ensure_order_cancel_reason!(code: "customer_changed_mind", name: "Клиент передумал")
    login_as!(@barista)
    order = Order.create!(
      tenant: @tenant,
      cash_shift: @shift,
      order_number: "BG-C2",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    assert_difference "AdminAuditLog.count", 1 do
      post "/barista/orders/#{order.id}/cancel",
        params: { reason: "Клиент передумал", reason_code: "customer_changed_mind" }
    end

    assert_equal "cancelled", order.reload.status
    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal "order_cancelled", log.action
    assert_equal "Клиент передумал", log.details["cancel_reason"]
  end

  test "shift close records shortage when closing cash below expected" do
    @shift.update!(opening_cash: 500)
    @shift.close!(@barista, 450)
    assert_equal(-50, @shift.cash_difference)
    assert_equal "closed", @shift.status
  end
end
