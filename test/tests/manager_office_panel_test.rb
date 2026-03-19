require "test_helper"

class ManagerOfficePanelTest < ActionDispatch::IntegrationTest
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

  test "office manager can open /manager and main pages" do
    tenant = create_tenant!(name: "T1", slug: "t1")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar@test.com", name: "Bar")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office@test.com", name: "Office")

    login_as!(office)

    get "/manager"
    assert_response :success
    assert_includes response.body, "Офис-менеджер"

    %w[
      /manager/orders
      /manager/finance/payments
      /manager/finance/refunds
      /manager/finance/fiscal_receipts
      /manager/shifts
      /manager/inventory
      /manager/menu
      /manager/reports
      /manager/staff
      /manager/devices
      /manager/incidents
    ].each do |path|
      get path
      assert_response :success, "Expected 200 for #{path}, got #{response.status}"
    end
  end

  test "office menu shows sold_out indicator and reason" do
    tenant = create_tenant!(name: "TMenu", slug: "tmenu")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office-menu@test.com", name: "OfficeMenu")

    category = create_category!(name: "КатMenu")
    product = Product.create!(name: "ПрMenu", slug: "пр-menu", category: category, sort_order: 1)

    # Для sold_out=true обязателен sold_out_reason (валидация в ProductTenantSetting)
    ProductTenantSetting.create!(
      tenant: tenant,
      product: product,
      price: 123,
      is_enabled: true,
      is_sold_out: true,
      sold_out_reason: "manual"
    )

    login_as!(office)
    get "/manager/menu"
    assert_response :success
    assert_includes response.body, "sold_out"
    assert_includes response.body, "manual"
    assert_includes response.body, "price: 123.0 ₽"
    assert_includes response.body, "enabled"
  end

  test "office inventory shows qty/min_qty and out of stock ingredients" do
    tenant = create_tenant!(name: "TInv", slug: "tinv")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office-inv@test.com", name: "OfficeInv")

    ingredient = Ingredient.create!(name: "ing-inv", unit: "g", is_active: true)
    stock = IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 0, min_qty: 1)

    login_as!(office)
    get "/manager/inventory"
    assert_response :success
    assert_includes response.body, ingredient.name
    assert_includes response.body, "qty: #{stock.qty}"
    assert_includes response.body, "min: #{stock.min_qty}"
  end

  test "office devices show online and offline labels" do
    tenant = create_tenant!(name: "TDev", slug: "tdev")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office-dev@test.com", name: "OfficeDev")

    online_device = Device.create!(
      tenant: tenant,
      device_type: "kiosk",
      name: "dev-online",
      device_token: SecureRandom.hex(6),
      is_active: true,
      last_seen_at: Time.current,
      token_expires_at: nil,
      registered_by: nil
    )
    offline_device = Device.create!(
      tenant: tenant,
      device_type: "kiosk",
      name: "dev-offline",
      device_token: SecureRandom.hex(6),
      is_active: true,
      last_seen_at: 10.minutes.ago,
      token_expires_at: nil,
      registered_by: nil
    )

    login_as!(office)
    get "/manager/devices"
    assert_response :success
    assert_includes response.body, online_device.name
    assert_includes response.body, "online"
    assert_includes response.body, offline_device.name
    assert_includes response.body, "offline"
  end

  test "office staff shows users and their role codes" do
    tenant = create_tenant!(name: "TStaff", slug: "tstaff")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office-staff@test.com", name: "OfficeStaff")

    user_a = create_user!(tenant: tenant, role_codes: %w[barista], email: "staff-bar@test.com", name: "StaffBar")
    user_b = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "staff-mgr@test.com", name: "StaffMgr")

    login_as!(office)
    get "/manager/staff"
    assert_response :success
    assert_includes response.body, user_a.name
    assert_includes response.body, "barista"
    assert_includes response.body, user_b.name
    assert_includes response.body, "shift_manager"
  end

  test "office reports compute counts and sums by from/to" do
    tenant = create_tenant!(name: "TRpt", slug: "trpt")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office-rpt@test.com", name: "OfficeRpt")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar-rpt@test.com", name: "BarRpt")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    from = Time.zone.now - 2.days
    to = Time.zone.now + 2.days

    in_range_order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 100)
    out_range_order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 999)
    in_range_order.update!(created_at: from + 1.day)
    out_range_order.update!(created_at: to + 2.days)

    cancelled_in_range_order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "cancelled", amount: 50)
    cancelled_in_range_order.update!(created_at: from + 1.day + 2.hours)

    create_payment!(tenant: tenant, order: in_range_order, amount: 100, status: "succeeded", method: "cash")
    create_payment!(tenant: tenant, order: out_range_order, amount: 999, status: "succeeded", method: "cash")
    create_refund!(tenant: tenant, order: in_range_order, payment: in_range_order.payments.first, amount: 10, status: "succeeded", reason: "r1")

    # Добавим ещё succeeded refund для проверки суммы
    create_refund!(tenant: tenant, order: in_range_order, payment: in_range_order.payments.first, amount: 5, status: "succeeded", reason: "r2")

    # Важное: refund/refund_payment created_at должны попасть в диапазон, чтобы учитываться
    in_range_payment = in_range_order.payments.first
    in_range_payment.update!(created_at: from + 1.day)
    in_range_payment.fiscal_receipts.destroy_all

    in_range_payment.refunds.each { |r| r.update!(created_at: from + 1.day) }

    out_range_payment = out_range_order.payments.first
    out_range_payment.update!(created_at: to + 2.days)

    login_as!(office)
    get "/manager/reports",
      params: {
        from: (from + 0.hours).iso8601,
        to: (to + 0.hours).iso8601
      }

    assert_response :success
    assert_includes response.body, "cancelled</span><span>1</span>"
    assert_includes response.body, "revenue (succeeded)"
    assert_includes response.body, "100.0 ₽"
    assert_includes response.body, "refunds (succeeded)"
    assert_includes response.body, "15.0 ₽"
  end

  test "barista is denied for /manager" do
    tenant = create_tenant!(name: "T2", slug: "t2")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar2@test.com", name: "Bar2")

    login_as!(barista)

    get "/manager"
    assert_response :redirect
  end

  test "barista status update is reflected on office orders list" do
    tenant = create_tenant!(name: "T3", slug: "t3")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar3@test.com", name: "Bar3")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office3@test.com", name: "Office3")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 120)
    product, _category = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 120)

    login_as!(barista)
    patch "/barista/orders/#{order.id}/update_status",
      params: { status: "preparing" },
      headers: { "ACCEPT" => "text/html" }
    assert_response :redirect

    login_as!(office)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, order.order_number
    assert_includes response.body, "preparing"
  end

  test "barista cancel is reflected on office orders list" do
    tenant = create_tenant!(name: "T4", slug: "t4")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar4@test.com", name: "Bar4")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office4@test.com", name: "Office4")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    OrderCancelReason.create!(
      code: "barista_cancel",
      name: "Отменено баристой",
      description: "Отмена заказа баристой",
      sort_order: 1,
      is_active: true
    )
    order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 200)
    product, _category = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 200)

    login_as!(barista)
    post "/barista/orders/#{order.id}/cancel",
      params: { reason: "Отменено баристой", reason_code: "barista_cancel" },
      headers: { "ACCEPT" => "text/html" }
    assert_response :redirect

    login_as!(office)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, order.order_number
    assert_includes response.body, "cancelled"
  end

  test "office incidents show pending payment, failed fiscal receipt, pending refund, offline device, out of stock" do
    tenant = create_tenant!(name: "T5", slug: "t5")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar5@test.com", name: "Bar5")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office5@test.com", name: "Office5")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 300)
    product, _category = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 300)

    pending_payment = create_payment!(tenant: tenant, order: order, amount: 300, status: "pending")
    succeeded_payment = create_payment!(tenant: tenant, order: order, amount: 300, status: "succeeded")
    failed_receipt = create_fiscal_receipt!(tenant: tenant, order: order, payment: succeeded_payment, status: "failed")
    pending_refund = create_refund!(tenant: tenant, order: order, payment: succeeded_payment, amount: 50, status: "pending")

    offline_device = create_device!(tenant: tenant, last_seen_at: 10.minutes.ago)
    out_stock = create_out_of_stock_ingredient!(tenant: tenant)

    login_as!(office)
    get "/manager/incidents"
    assert_response :success

    assert_includes response.body, order.order_number
    assert_includes response.body, pending_payment.status
    assert_includes response.body, failed_receipt.type
    assert_includes response.body, failed_receipt.status
    assert_includes response.body, pending_refund.status
    assert_includes response.body, pending_refund.reason
    assert_includes response.body, offline_device.name
    assert_includes response.body, out_stock.ingredient.name
  end

  test "Close Shift Wizard blocks closing when there are blockers" do
    tenant = create_tenant!(name: "T6", slug: "t6")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar6@test.com", name: "Bar6")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office6@test.com", name: "Office6")

    shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    OrderCancelReason.create!(
      code: "barista_cancel",
      name: "Отменено баристой",
      description: "Отмена заказа баристой",
      sort_order: 1,
      is_active: true
    )
    order = create_order!(tenant: tenant, cash_shift: shift, status: "accepted", amount: 100)
    product, _category = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 100)

    pending_payment = create_payment!(tenant: tenant, order: order, amount: 100, status: "pending")
    succeeded_payment = create_payment!(tenant: tenant, order: order, amount: 100, status: "succeeded")
    create_fiscal_receipt!(tenant: tenant, order: order, payment: succeeded_payment, status: "failed")
    create_refund!(tenant: tenant, order: order, payment: succeeded_payment, amount: 10, status: "pending")

    login_as!(office)
    get "/manager/shifts/#{shift.id}/close"
    assert_response :success
    assert_includes response.body, "Проверки"
    assert_includes response.body, "Зависшие платежи"

    post "/manager/shifts/#{shift.id}/close",
      params: { closing_cash: 10 },
      headers: { "ACCEPT" => "text/html" }
    assert_response :redirect

    follow_redirect!
    assert_includes response.body, "Нельзя закрыть смену"
    assert_equal "open", CashShift.find(shift.id).reload.status
  end

  test "Close Shift Wizard closes shift when there are no blockers" do
    tenant = create_tenant!(name: "T7", slug: "t7")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar7@test.com", name: "Bar7")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office7@test.com", name: "Office7")

    shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: shift, status: "accepted", amount: 120)
    product, _category = create_product_fixture!(tenant: tenant)
    create_order_item!(order: order, product: product, quantity: 1, unit_price: 120)

    create_payment!(tenant: tenant, order: order, amount: 120, status: "succeeded")
    payment_for_receipt = create_payment!(tenant: tenant, order: order, amount: 120, status: "succeeded")
    create_fiscal_receipt!(tenant: tenant, order: order, payment: payment_for_receipt, status: "confirmed")
    create_refund!(tenant: tenant, order: order, payment: payment_for_receipt, amount: 10, status: "succeeded")

    login_as!(office)
    post "/manager/shifts/#{shift.id}/close", params: { closing_cash: 999 }
    assert_response :redirect

    assert_equal "closed", CashShift.find(shift.id).reload.status
  end

  test "office closing shift makes barista see 'Смена закрыта' and blocks order creation" do
    tenant = create_tenant!(name: "T8", slug: "t8")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar8@test.com", name: "Bar8")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office8@test.com", name: "Office8")

    shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    # Office closes shift
    login_as!(office)
    post "/manager/shifts/#{shift.id}/close", params: { closing_cash: 100 }
    assert_equal "closed", CashShift.find(shift.id).reload.status

    # Barista dashboard should show shift closed
    login_as!(barista)
    get "/barista"
    assert_response :success
    assert_includes response.body, "Смена закрыта"

    # Barista cannot create order when shift is closed
    category = create_category!(name: "Кат8")
    product = create_product!(category: category, name: "Пр8")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 50, is_sold_out: false, is_enabled: true)

    post "/barista/orders", params: {
      cart_items: [{ product_id: product.id, quantity: 1 }],
      payment_method: "cash"
    }
    follow_redirect!
    assert_includes response.body, "Смена закрыта"
  end

  test "barista turbo: invalid status transition returns turbo-stream replace" do
    tenant = create_tenant!(name: "T9", slug: "t9")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar9@test.com", name: "Bar9")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office9@test.com", name: "Office9")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "issued", amount: 100)

    login_as!(barista)
    patch "/barista/orders/#{order.id}/update_status",
      params: { status: "cancelled" },
      headers: turbo_headers

    assert_response :success
    assert_includes response.body, "action=\"replace\""
    assert_includes response.body, "target=\"order_#{order.id}\""
    assert_equal "issued", Order.find(order.id).reload.status

    login_as!(office)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, "issued"
  end

  test "barista turbo: cancel order returns turbo-stream remove" do
    tenant = create_tenant!(name: "T10", slug: "t10")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar10@test.com", name: "Bar10")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office10@test.com", name: "Office10")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    OrderCancelReason.create!(
      code: "barista_cancel",
      name: "Отменено баристой",
      description: "Отмена заказа баристой",
      sort_order: 1,
      is_active: true
    )
    order = create_order!(tenant: tenant, cash_shift: cash_shift, status: "accepted", amount: 130)

    login_as!(barista)
    post "/barista/orders/#{order.id}/cancel",
      params: { reason: "Отменено", reason_code: "barista_cancel" },
      headers: turbo_headers

    assert_response :success
    assert_includes response.body, "action=\"remove\""
    assert_includes response.body, "target=\"order_#{order.id}\""
    assert_equal "cancelled", Order.find(order.id).reload.status

    login_as!(office)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, "cancelled"
  end
end

