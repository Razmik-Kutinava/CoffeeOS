require "test_helper"

class Barista::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant  = create_tenant!(name: "BaristaCtrl", slug: "barista-ctrl-#{SecureRandom.hex(3)}")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "bctrl@test.local", name: "BCtrl")
    @shift   = open_cash_shift!(tenant: @tenant, opened_by: @barista)

    category  = create_category!
    @product  = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200, is_enabled: true, is_sold_out: false)
  end

  # ── авторизация ────────────────────────────────────────────────────────────

  test "unauthenticated user cannot create order" do
    post "/barista/orders", params: { cart_items: [ { product_id: @product.id, quantity: 1 } ] }
    assert_response :redirect
    assert_no_orders_created
  end

  test "manager cannot create order via barista endpoint" do
    manager = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "mgr-bctrl@test.local", name: "Mgr")
    login_as!(manager)
    post "/barista/orders", params: { cart_items: [ { product_id: @product.id, quantity: 1 } ] }
    assert_no_orders_created
  end

  # ── создание заказа ────────────────────────────────────────────────────────

  test "barista creates order successfully with UUID product_id" do
    login_as!(@barista)
    before = Order.where(tenant: @tenant).count

    post "/barista/orders", params: {
      cart_items: [ { "product_id" => @product.id.to_s, "quantity" => "2" } ],
      payment_method: "cash"
    }

    assert_response :redirect
    assert_equal before + 1, Order.where(tenant: @tenant).count
    order = Order.where(tenant: @tenant).order(created_at: :desc).first
    assert_equal "accepted", order.status
    assert_equal 400.to_d, order.total_amount
  end

  test "barista cannot create order without open shift" do
    @shift.update!(status: "closed")
    login_as!(@barista)
    before = Order.where(tenant: @tenant).count

    post "/barista/orders", params: {
      cart_items: [ { "product_id" => @product.id.to_s, "quantity" => "1" } ]
    }

    assert_response :redirect
    assert_equal before, Order.where(tenant: @tenant).count
  end

  test "barista cannot order sold_out product" do
    ProductTenantSetting.find_by!(tenant: @tenant, product: @product).update!(is_sold_out: true, sold_out_reason: "manual")
    login_as!(@barista)
    before = Order.where(tenant: @tenant).count

    post "/barista/orders", params: {
      cart_items: [ { "product_id" => @product.id.to_s, "quantity" => "1" } ]
    }

    assert_response :redirect
    assert_equal before, Order.where(tenant: @tenant).count, "Sold out product must not create order"
  end

  test "error message does not expose internal exception to user" do
    # Сломанный продукт — несуществующий ID
    login_as!(@barista)
    post "/barista/orders", params: {
      cart_items: [ { "product_id" => SecureRandom.uuid, "quantity" => "1" } ]
    }

    follow_redirect!
    assert_no_match /RecordNotFound|ActiveRecord|backtrace/, response.body
  end

  test "invalid date param does not crash history endpoint" do
    login_as!(@barista)
    get "/barista/orders/history", params: { date: "not-a-date" }
    assert_response :success
  end

  # ── изоляция смен ──────────────────────────────────────────────────────────

  test "barista can show and update order from current open shift" do
    login_as!(@barista)
    order = Order.create!(
      tenant: @tenant, cash_shift: @shift,
      order_number: "CUR-001", source: "manual", status: "accepted",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )

    get "/barista/orders/#{order.id}.json"
    assert_response :success
    assert_equal order.id, response.parsed_body["id"]

    patch "/barista/orders/#{order.id}/update_status", params: { status: "preparing" }
    assert_equal "preparing", order.reload.status
  end

  test "barista can access vitrina mobile order created after shift opened" do
    login_as!(@barista)
    vitrina = Order.create!(
      tenant: @tenant, cash_shift: nil,
      order_number: "VIT-CUR", source: "mobile", status: "accepted",
      total_amount: 200, discount_amount: 0, final_amount: 200,
      created_at: @shift.opened_at + 1.minute
    )

    get "/barista/orders/#{vitrina.id}.json"
    assert_response :success

    patch "/barista/orders/#{vitrina.id}/update_status", params: { status: "preparing" }
    assert_equal "preparing", vitrina.reload.status
  end

  test "barista cannot access accepted order from closed previous shift of same tenant" do
    stale = Order.create!(
      tenant: @tenant, cash_shift: @shift,
      order_number: "OLD-SHIFT", source: "manual", status: "accepted",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )
    @shift.update!(status: "closed", closed_at: Time.current, closed_by: @barista, closing_cash: 0)
    open_cash_shift!(tenant: @tenant, opened_by: @barista)

    login_as!(@barista)

    get "/barista/orders/#{stale.id}.json"
    assert_response :not_found

    patch "/barista/orders/#{stale.id}/update_status", params: { status: "preparing" }
    assert_equal "accepted", stale.reload.status

    post "/barista/orders/#{stale.id}/cancel", params: { reason: "test" }
    assert_equal "accepted", stale.reload.status
  end

  test "barista can update carryover preparing order from closed previous shift" do
    carryover = Order.create!(
      tenant: @tenant, cash_shift: @shift,
      order_number: "CARRY-PREP", source: "manual", status: "preparing",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )
    @shift.update!(status: "closed", closed_at: Time.current, closed_by: @barista, closing_cash: 0)
    open_cash_shift!(tenant: @tenant, opened_by: @barista)

    login_as!(@barista)

    get "/barista/orders/#{carryover.id}.json"
    assert_response :success

    patch "/barista/orders/#{carryover.id}/update_status", params: { status: "ready" }
    assert_equal "ready", carryover.reload.status
  end

  test "show without open shift returns forbidden json" do
    @shift.update!(status: "closed", closed_at: Time.current, closed_by: @barista, closing_cash: 0)
    order = Order.create!(
      tenant: @tenant, cash_shift: @shift,
      order_number: "NO-SHIFT", source: "manual", status: "accepted",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )

    login_as!(@barista)
    get "/barista/orders/#{order.id}.json"
    assert_response :forbidden
  end

  # ── изоляция тенантов ──────────────────────────────────────────────────────

  # ── аудит отмены ───────────────────────────────────────────────────────────

  test "cancelling order creates AdminAuditLog record" do
    login_as!(@barista)
    order = Order.create!(
      tenant: @tenant, cash_shift: @shift,
      order_number: "AUD-001", source: "manual", status: "accepted",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )

    assert_difference "AdminAuditLog.count", 1 do
      post "/barista/orders/#{order.id}/cancel", params: { reason: "Клиент передумал" }
    end

    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal "order_cancelled", log.action
    assert_equal order.id, log.entity_id
    assert_equal "Order", log.entity_type
    assert_equal @tenant.id, log.tenant_id
    assert_equal "Клиент передумал", log.details["cancel_reason"]
  end

  test "barista cannot update status of another tenant's order" do
    other_tenant  = create_tenant!(name: "Other", slug: "other-#{SecureRandom.hex(3)}")
    other_barista = create_user!(tenant: other_tenant, role_codes: %w[barista], email: "other-b@test.local", name: "OB")
    other_shift   = open_cash_shift!(tenant: other_tenant, opened_by: other_barista)
    other_order   = Order.create!(
      tenant: other_tenant, cash_shift: other_shift,
      order_number: "OTHER-001", source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100
    )

    login_as!(@barista)
    patch "/barista/orders/#{other_order.id}/status", params: { status: "preparing" }

    other_order.reload
    assert_equal "accepted", other_order.status, "Barista from another tenant must not change this order"
  end

  private

  def assert_no_orders_created
    assert_equal 0, Order.where(tenant: @tenant).count
  end
end
