require "test_helper"

class ManagerVolumeTest < ActionDispatch::IntegrationTest
  def create_order!(tenant:, cash_shift:, order_number:, status: "accepted", amount: 100)
    Order.create!(
      tenant: tenant,
      cash_shift: cash_shift,
      order_number: order_number,
      source: "manual",
      status: status,
      total_amount: amount,
      discount_amount: 0,
      final_amount: amount
    )
  end

  def create_payment!(tenant:, order:, amount:, status: "pending", method: "cash", provider: "manual")
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

  test "volume: manager orders limit 200 and shift-manager incidents queues cap at 50" do
    tenant = create_tenant!(name: "TVol", slug: "tvol")

    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "vol-bar@test.com", name: "VolBar")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "vol-office@test.com", name: "VolOffice")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "vol-mgr@test.com", name: "VolMgr")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    now = Time.zone.now

    # 1) Базовый объём: 250 accepted заказов для проверки /manager/orders limit(200) и бариста колонок limit(50)
    250.times do |i|
      order = create_order!(
        tenant: tenant,
        cash_shift: cash_shift,
        order_number: "LIMIT-#{i}",
        status: "accepted",
        amount: 100
      )
      # Управляем ordering: i=0 самый новый, i=249 самый старый.
      order.update!(created_at: now - i.minutes)
    end

    # 2) Очереди инцидентов для shift-manager (чтобы сработал cap=50)
    # Сделаем их сильно "старее", чтобы они не мешали /manager/orders limit(200).
    pending_payment_orders = []
    60.times do |i|
      o = create_order!(
        tenant: tenant,
        cash_shift: cash_shift,
        order_number: "INC-PAY-#{i}",
        status: "closed",
        amount: 100
      )
      o.update!(created_at: now - (10_000 + i).minutes)
      pending_payment_orders << o
    end

    pending_payment_orders.each_with_index do |order, idx|
      p = create_payment!(tenant: tenant, order: order, amount: 100, status: "pending")
      p.update!(created_at: order.created_at)
    end

    failed_receipt_orders = []
    60.times do |i|
      o = create_order!(
        tenant: tenant,
        cash_shift: cash_shift,
        order_number: "INC-FAIL-#{i}",
        status: "closed",
        amount: 120
      )
      o.update!(created_at: now - (20_000 + i).minutes)
      failed_receipt_orders << o
    end

    failed_receipt_orders.each do |order|
      succeeded_payment = create_payment!(tenant: tenant, order: order, amount: 120, status: "succeeded")
      succeeded_payment.update!(created_at: order.created_at)
      create_fiscal_receipt!(tenant: tenant, order: order, payment: succeeded_payment, status: "failed", type: "payment")
    end

    pending_refund_orders = []
    60.times do |i|
      o = create_order!(
        tenant: tenant,
        cash_shift: cash_shift,
        order_number: "INC-REF-#{i}",
        status: "closed",
        amount: 50
      )
      o.update!(created_at: now - (30_000 + i).minutes)
      pending_refund_orders << o
    end

    pending_refund_orders.each do |order|
      succeeded_payment = create_payment!(tenant: tenant, order: order, amount: 50, status: "succeeded")
      succeeded_payment.update!(created_at: order.created_at)
      r = create_refund!(tenant: tenant, order: order, payment: succeeded_payment, amount: 10, status: "pending", reason: "r-refund")
      r.update!(created_at: order.created_at)
    end

    # 3) Проверка /manager/orders limit(200)
    login_as!(office)
    get "/manager/orders"
    assert_response :success

    assert_includes response.body, "LIMIT-0"
    assert_includes response.body, "LIMIT-199"
    assert_not_includes response.body, "LIMIT-200"
    assert_not_includes response.body, "LIMIT-249"

    # 4) Проверка /barista колонок limit(50)
    login_as!(barista)
    get "/barista"
    assert_response :success
    assert_includes response.body, 'id="count-new">50</span>'

    # 5) Проверка /manager/incidents cap=50 для очередей (shift-manager)
    login_as!(shift_manager)
    get "/manager/incidents"
    assert_response :success

    assert_equal 50, response.body.scan(/INC-PAY-\d+/).size
    assert_equal 50, response.body.scan(/INC-FAIL-\d+/).size
    assert_equal 50, response.body.scan(/INC-REF-\d+/).size
  end
end

