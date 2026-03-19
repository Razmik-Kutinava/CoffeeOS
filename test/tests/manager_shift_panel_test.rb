require "test_helper"

class ManagerShiftPanelTest < ActionDispatch::IntegrationTest
  def turbo_headers
    { "ACCEPT" => "text/vnd.turbo-stream.html" }
  end

  def create_order!(tenant:, cash_shift:, status: "accepted", source: "manual", amount: 100)
    Order.create!(
      tenant: tenant,
      cash_shift: cash_shift,
      order_number: "ORD-#{SecureRandom.hex(4)}",
      source: source,
      status: status,
      total_amount: amount,
      discount_amount: 0,
      final_amount: amount
    )
  end

  def create_order_item!(order:, product:, quantity: 1, unit_price: 100)
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: quantity,
      unit_price: unit_price,
      total_price: unit_price * quantity
    )
  end

  def create_payment!(tenant:, order:, amount:, status: "succeeded", method: "cash", provider: "manual")
    Payment.create!(
      tenant: tenant,
      order: order,
      amount: amount,
      method: method,
      provider: provider,
      status: status,
      paid_at: status == "succeeded" ? Time.current : nil
    )
  end

  def create_fiscal_receipt!(tenant:, order:, payment:, type: "payment", status: "failed")
    FiscalReceipt.create!(
      tenant: tenant,
      order: order,
      payment: payment,
      type: type,
      status: status,
      ofd_provider: "ofd-test",
      receipt_data: { "items" => [] }
    )
  end

  def create_refund!(tenant:, order:, payment:, amount:, status: "pending", reason: "refund-reason")
    Refund.create!(
      tenant: tenant,
      order: order,
      payment: payment,
      initiated_by: nil,
      amount: amount,
      reason: reason,
      status: status
    )
  end

  def create_device!(tenant:, last_seen_at: 10.minutes.ago)
    Device.create!(
      tenant: tenant,
      device_type: "kiosk",
      name: "device-#{SecureRandom.hex(3)}",
      device_token: SecureRandom.hex(6),
      is_active: true,
      last_seen_at: last_seen_at,
      token_expires_at: nil,
      registered_by: nil
    )
  end

  def create_out_of_stock_ingredient!(tenant:)
    ingredient = Ingredient.create!(
      name: "ing-#{SecureRandom.hex(3)}",
      unit: "g",
      is_active: true
    )

    IngredientTenantStock.create!(
      tenant: tenant,
      ingredient: ingredient,
      qty: 0,
      min_qty: 1
    )
  end

  def create_product_fixture!(tenant:)
    category = create_category!(name: "Кат-#{SecureRandom.hex(3)}")
    product = create_product!(category: category, name: "Пр-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 100, is_sold_out: false, is_enabled: true)
    [product, category]
  end

  test "shift_manager can open /manager and sees limited pages" do
    tenant = create_tenant!(name: "TS1", slug: "ts1")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar@test.com", name: "Bar")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "mgr@test.com", name: "Mgr")

    open_cash_shift!(tenant: tenant, opened_by: barista)
    login_as!(shift_manager)

    get "/manager"
    assert_response :success
    assert_includes response.body, "Менеджер смены"

    %w[
      /manager/orders
      /manager/finance/payments
      /manager/finance/refunds
      /manager/finance/fiscal_receipts
      /manager/shifts
      /manager/inventory
      /manager/menu
      /manager/reports
      /manager/incidents
    ].each do |path|
      get path
      assert_response :success, "Expected 200 for #{path}, got #{response.status}"
    end

    get "/manager/staff"
    assert_response :redirect

    get "/manager/devices"
    assert_response :redirect
  end

  test "shift_manager orders/payments/incidents are filtered to current open cash shift" do
    tenant = create_tenant!(name: "TS2", slug: "ts2")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar2@test.com", name: "Bar2")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "mgr2@test.com", name: "Mgr2")

    open_shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    closed_shift = CashShift.create!(
      tenant: tenant,
      status: "closed",
      opened_by: barista,
      opened_at: Time.current - 2.days,
      opening_cash: 0,
      closed_at: Time.current - 1.day,
      closing_cash: 0,
      closed_by: barista
    )

    order_open = create_order!(tenant: tenant, cash_shift: open_shift, status: "accepted", amount: 100)
    order_closed = create_order!(tenant: tenant, cash_shift: closed_shift, status: "accepted", amount: 200)

    product, = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order_open, product: product, quantity: 1, unit_price: 100)
    create_order_item!(order: order_closed, product: product, quantity: 1, unit_price: 200)

    pending_payment_open = create_payment!(tenant: tenant, order: order_open, amount: 100, status: "pending")
    pending_payment_closed = create_payment!(tenant: tenant, order: order_closed, amount: 200, status: "pending")

    succeeded_payment_open = create_payment!(tenant: tenant, order: order_open, amount: 100, status: "succeeded")
    succeeded_payment_closed = create_payment!(tenant: tenant, order: order_closed, amount: 200, status: "succeeded")

    failed_receipt_open = create_fiscal_receipt!(tenant: tenant, order: order_open, payment: succeeded_payment_open, status: "failed")
    failed_receipt_closed = create_fiscal_receipt!(tenant: tenant, order: order_closed, payment: succeeded_payment_closed, status: "failed")

    pending_refund_open = create_refund!(tenant: tenant, order: order_open, payment: succeeded_payment_open, amount: 10, status: "pending")
    pending_refund_closed = create_refund!(tenant: tenant, order: order_closed, payment: succeeded_payment_closed, amount: 20, status: "pending")

    offline_device = create_device!(tenant: tenant, last_seen_at: 10.minutes.ago)
    out_stock = create_out_of_stock_ingredient!(tenant: tenant)

    login_as!(shift_manager)

    get "/manager/orders"
    assert_response :success
    assert_includes response.body, order_open.order_number
    assert_not_includes response.body, order_closed.order_number

    get "/manager/finance/payments"
    assert_response :success
    assert_includes response.body, order_open.order_number
    assert_not_includes response.body, order_closed.order_number

    get "/manager/incidents"
    assert_response :success

    # shift-scoped queues
    assert_includes response.body, order_open.order_number
    assert_not_includes response.body, order_closed.order_number

    # tenant-level sources (offline/out_of_stock) - должны по-прежнему появляться
    assert_includes response.body, offline_device.name
    assert_includes response.body, out_stock.ingredient.name

    # sanity checks for queue entries
    assert_includes response.body, pending_payment_open.status
    assert_includes response.body, failed_receipt_open.status
    assert_includes response.body, pending_refund_open.reason
  end

  test "shift_manager Close Shift Wizard closes only current open cash shift" do
    tenant = create_tenant!(name: "TS3", slug: "ts3")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar3@test.com", name: "Bar3")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "mgr3@test.com", name: "Mgr3")

    open_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    closed_shift = CashShift.create!(
      tenant: tenant,
      status: "closed",
      opened_by: barista,
      opened_at: Time.current - 2.days,
      opening_cash: 0,
      closed_at: Time.current - 1.day,
      closing_cash: 0,
      closed_by: barista
    )

    order = create_order!(tenant: tenant, cash_shift: open_shift, status: "accepted", amount: 100)
    product, = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 100)

    # block closing
    create_payment!(tenant: tenant, order: order, amount: 100, status: "pending")
    succeeded_payment = create_payment!(tenant: tenant, order: order, amount: 100, status: "succeeded")
    create_fiscal_receipt!(tenant: tenant, order: order, payment: succeeded_payment, status: "failed")
    create_refund!(tenant: tenant, order: order, payment: succeeded_payment, amount: 10, status: "pending")

    login_as!(shift_manager)

    get "/manager/shifts/#{open_shift.id}/close"
    assert_response :success

    post "/manager/shifts/#{open_shift.id}/close", params: { closing_cash: 10 }, headers: { "ACCEPT" => "text/html" }
    assert_response :redirect
    assert_equal "open", CashShift.find(open_shift.id).reload.status

    # cannot close a non-current (already closed) shift
    post "/manager/shifts/#{closed_shift.id}/close", params: { closing_cash: 10 }, headers: { "ACCEPT" => "text/html" }
    assert_response :redirect
    assert_equal "closed", CashShift.find(closed_shift.id).reload.status
  end

  test "barista status update is reflected on shift manager orders list" do
    tenant = create_tenant!(name: "TS4", slug: "ts4")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar4@test.com", name: "Bar4")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "mgr4@test.com", name: "Mgr4")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 120)
    product, = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 120)

    login_as!(barista)
    OrderCancelReason.create!(
      code: "barista_cancel",
      name: "Отменено баристой",
      description: "Отмена заказа баристой",
      sort_order: 1,
      is_active: true
    )

    patch "/barista/orders/#{order.id}/update_status",
      params: { status: "preparing" },
      headers: { "ACCEPT" => "text/html" }
    assert_response :redirect

    login_as!(shift_manager)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, order.order_number
    assert_includes response.body, "preparing"
  end

  test "shift_manager reports are scoped to current open cash shift" do
    tenant = create_tenant!(name: "TSR", slug: "tsr")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar-rpt@test.com", name: "BarRpt")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "mgr-rpt@test.com", name: "MgrRpt")

    open_shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    closed_shift = CashShift.create!(
      tenant: tenant,
      status: "closed",
      opened_by: barista,
      opened_at: Time.current - 2.days,
      opening_cash: 0,
      closed_at: Time.current - 1.day,
      closing_cash: 0,
      closed_by: barista
    )

    from = Time.zone.now - 2.days
    to = Time.zone.now + 2.days

    open_order = create_order!(tenant: tenant, cash_shift: open_shift, status: "accepted", amount: 100)
    open_order.update!(created_at: from + 1.day)

    cancelled_open_order = create_order!(tenant: tenant, cash_shift: open_shift, status: "cancelled", amount: 10)
    cancelled_open_order.update!(created_at: from + 1.day + 1.hour)

    closed_order = create_order!(tenant: tenant, cash_shift: closed_shift, status: "accepted", amount: 200)
    closed_order.update!(created_at: from + 1.day + 2.hours)

    open_payment = create_payment!(tenant: tenant, order: open_order, amount: 100, status: "succeeded", method: "cash")
    open_payment.update!(created_at: from + 1.day)

    closed_payment = create_payment!(tenant: tenant, order: closed_order, amount: 200, status: "succeeded", method: "cash")
    closed_payment.update!(created_at: from + 1.day)

    # refunds: только по open_shift должны попадать в отчёт
    create_refund!(tenant: tenant, order: open_order, payment: open_payment, amount: 7, status: "succeeded", reason: "r-open")
    create_refund!(tenant: tenant, order: closed_order, payment: closed_payment, amount: 9, status: "succeeded", reason: "r-closed")

    login_as!(shift_manager)
    get "/manager/reports",
      params: {
        from: (from + 0.hours).iso8601,
        to: (to + 0.hours).iso8601
      }

    assert_response :success
    assert_includes response.body, "count</span><span class=\"accent\">2</span>"
    assert_includes response.body, "cancelled</span><span>1</span>"
    assert_includes response.body, "revenue (succeeded)"
    assert_includes response.body, "100.0 ₽"
    assert_includes response.body, "refunds (succeeded)"
    assert_includes response.body, "7.0 ₽"
  end
end


