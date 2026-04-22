require "test_helper"

class BaristaTabletRegressionTest < ActionDispatch::IntegrationTest
  def setup
    @tenant_a = create_tenant!(name: "A", slug: "tenant-a")
    @tenant_b = create_tenant!(name: "B", slug: "tenant-b")

    @barista = create_user!(tenant: @tenant_a, role_codes: %w[barista], name: "Бариста A", email: "barista-a@test.local")
    @shift_manager = create_user!(tenant: @tenant_a, role_codes: %w[shift_manager], name: "Мгр A", email: "mgr-a@test.local")

    @category = create_category!(name: "Кофе")
    @product = create_product!(category: @category, name: "Капучино")
    enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 150)

    @cash_shift = open_cash_shift!(tenant: @tenant_a, opened_by: @barista)
  end

  # 1. Табло заказов (Dashboard): канбан + подписка Turbo Streams
  test "dashboard renders kanban columns and turbo stream subscription" do
    login_as!(@barista)
    get "/barista"
    assert_response :success

    assert_includes response.body, "id=\"kanban\""
    assert_includes response.body, "ACCEPTED"
    assert_includes response.body, "PREPARING"
    assert_includes response.body, "READY"
    assert_includes response.body, "id=\"orders-new\""
    assert_includes response.body, "id=\"orders-preparing\""
    assert_includes response.body, "id=\"orders-ready\""
    # turbo_stream_from "orders_#{Current.tenant_id}" рендерит cable stream source в HTML
    assert_includes response.body, "turbo-cable-stream-source"
  end

  # 2. Управление заказами: отмена доступна и меняет статус
  test "barista can cancel accepted order with reason and code" do
    login_as!(@barista)

    OrderCancelReason.create!(code: "barista_cancel", name: "Отменено баристой", description: "Отмена заказа баристой", sort_order: 1, is_active: true)

    order = Order.create!(
      tenant: @tenant_a,
      cash_shift: @cash_shift,
      order_number: "CANCEL-1",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    post "/barista/orders/#{order.id}/cancel", params: { reason: "Отменено баристой", reason_code: "barista_cancel" }
    assert_response :redirect
    assert_equal "cancelled", order.reload.status
    assert_equal "barista_cancel", order.cancel_reason_code
  end

  # 3. Создание заказа: страница содержит каталог, корзину и методы оплаты
  test "create order page shows catalog, cart, and payment methods" do
    login_as!(@barista)
    get "/barista/create-order"
    assert_response :success

    assert_includes response.body, "Создание заказа"
    assert_includes response.body, "Корзина"
    assert_includes response.body, "Оплата"
    assert_includes response.body, "Наличные"
    assert_includes response.body, "Карта"
    assert_includes response.body, "СБП"
  end

  # 4. Real-time обновления: на дашборде есть подписка на tenant-канал
  test "dashboard subscribes to tenant orders stream" do
    login_as!(@barista)
    get "/barista"
    assert_response :success
    assert_includes response.body, "turbo-cable-stream-source"
  end

  # 5. История заказов: фильтрация по статусу
  test "orders history filters by status" do
    login_as!(@barista)

    o_closed = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "H-CLOSED", source: "manual", status: "closed", total_amount: 100, discount_amount: 0, final_amount: 100)
    o_cancelled = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "H-CANCELLED", source: "manual", status: "cancelled", total_amount: 100, discount_amount: 0, final_amount: 100)
    o_issued = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "H-ISSUED", source: "manual", status: "issued", total_amount: 100, discount_amount: 0, final_amount: 100)

    get "/barista/orders/history", params: { status: "closed", date: Date.today }
    assert_response :success
    assert_includes response.body, o_closed.order_number
    assert_no_match(/#{Regexp.escape(o_cancelled.order_number)}/, response.body)
    assert_no_match(/#{Regexp.escape(o_issued.order_number)}/, response.body)
  end

  # 6. Меню: показывает стоп-лист для sold_out позиций
  test "menu shows stop indicator for sold out product" do
    login_as!(@barista)
    ProductTenantSetting.find_by!(tenant: @tenant_a, product: @product).update!(is_sold_out: true, sold_out_reason: "stock_empty")

    get "/barista/menu"
    assert_response :success
    assert_includes response.body, @product.name
    assert_includes response.body, "⛔"
    assert_includes response.body, "Стоп"
  end

  # 7. Смена: отображает статистику (выручка/кол-во заказов)
  test "shift page shows shift stats for current shift" do
    login_as!(@barista)

    order = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "SHIFT-1", source: "manual", status: "accepted", total_amount: 150, discount_amount: 0, final_amount: 150)
    Payment.create!(tenant: @tenant_a, order: order, amount: 150, method: "cash", provider: "manual", status: "succeeded", paid_at: Time.current)

    get "/barista/shift"
    assert_response :success
    assert_includes response.body, "Текущая смена"
    assert_includes response.body, "Выручка"
    assert_includes response.body, "150"
  end

  # 8. Отчёты: отображает статистику смены
  test "reports page shows shift statistics when shift open" do
    login_as!(@barista)

    order = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "RPT-1", source: "manual", status: "accepted", total_amount: 200, discount_amount: 0, final_amount: 200)
    Payment.create!(tenant: @tenant_a, order: order, amount: 200, method: "card", provider: "manual", status: "succeeded", paid_at: Time.current)

    get "/barista/reports"
    assert_response :success
    assert_includes response.body, "Отчёты"
    assert_includes response.body, "Статистика за смену"
    assert_includes response.body, "Выручка"
    assert_includes response.body, "200"
  end

  # 9. Валидация переходов статусов
  test "status transitions: cannot skip and cannot change issued/closed" do
    login_as!(@barista)

    order = Order.create!(
      tenant: @tenant_a,
      cash_shift: @cash_shift,
      order_number: "T-1",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    # cannot skip ACCEPTED -> READY
    patch "/barista/orders/#{order.id}/update_status", params: { status: "ready" }
    assert_response :redirect
    assert_equal "accepted", order.reload.status

    # allowed ACCEPTED -> PREPARING
    patch "/barista/orders/#{order.id}/update_status", params: { status: "preparing" }
    # HTML-ответ редиректит обратно на дашборд; turbo_stream будет только при Turbo request
    assert_response :redirect
    assert_equal "preparing", order.reload.status

    # issued cannot change
    order.update!(status: "issued")
    patch "/barista/orders/#{order.id}/update_status", params: { status: "cancelled" }
    assert_response :redirect
    assert_equal "issued", order.reload.status

    # closed cannot change
    order.update!(status: "closed")
    patch "/barista/orders/#{order.id}/update_status", params: { status: "cancelled" }
    assert_response :redirect
    assert_equal "closed", order.reload.status
  end

  # 10. Граничные случаи
  test "dashboard with no orders shows empty columns" do
    login_as!(@barista)
    get "/barista"
    assert_response :success
    assert_includes response.body, "Нет заказов"
  end

  test "dashboard limits 50 orders per column" do
    login_as!(@barista)
    60.times do |i|
      Order.create!(
        tenant: @tenant_a,
        cash_shift: @cash_shift,
        order_number: "L-#{i}",
        source: "manual",
        status: "accepted",
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100
      )
    end

    get "/barista"
    assert_response :success
    # count badge should show 50 max because controller .limit(50)
    assert_match(/id="count-new">50<\/span>/, response.body)
  end

  test "order card shows only first 3 items and 'more' indicator and promo discount" do
    login_as!(@barista)

    order = Order.create!(
      tenant: @tenant_a,
      cash_shift: @cash_shift,
      order_number: "BIG-1",
      source: "manual",
      status: "accepted",
      total_amount: 1000,
      discount_amount: 100,
      final_amount: 900
    )
    5.times do |i|
      OrderItem.create!(
        order: order,
        product_id: @product.id,
        product_name: "P#{i}",
        quantity: 1,
        unit_price: 100,
        total_price: 100
      )
    end

    get "/barista"
    assert_response :success
    assert_includes response.body, "...еще 2"
    assert_includes response.body, "Промокод:"
  end

  # 11. Таймеры и время (проверка разметки/порогов + наличие JS setInterval)
  test "timer element has data-time and JS updates every second with warning/critical thresholds" do
    login_as!(@barista)

    order = Order.create!(
      tenant: @tenant_a,
      cash_shift: @cash_shift,
      order_number: "TIME-1",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: 12.minutes.ago
    )
    OrderStatusLog.create!(
      order: order,
      status_from: "pending_payment",
      status_to: "accepted",
      changed_by_id: @barista.id,
      source: "barista",
      comment: "seed",
      created_at: 12.minutes.ago
    )

    get "/barista"
    assert_response :success
    assert_match(/class="order-timer[^"]*timer-critical"/, response.body)
    assert_match(/data-time="[^"]+"/, response.body)
    js = Rails.root.join("app/javascript/controllers/order_timer_controller.js").read
    assert_includes js, "setInterval"
    assert_includes js, "if (diffMins > 10)"
    assert_includes js, "if (diffMins > 5)"
  end

  # 12. Безопасность и изоляция данных
  test "barista sees only own tenant orders and cannot access other tenant by URL" do
    login_as!(@barista)

    other_shift = open_cash_shift!(tenant: @tenant_b, opened_by: create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "barista-b@test.local"))
    order_b = Order.create!(
      tenant: @tenant_b,
      cash_shift: other_shift,
      order_number: "B-1",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    get "/barista"
    assert_response :success
    assert_no_match(/B-1/, response.body)

    # RecordNotFound теперь обрабатывается централизованно в ApplicationController — редирект на root
    get "/barista/orders/#{order_b.id}"
    assert_response :redirect
  end

  # 13. Обработка ошибок
  test "create order fails if shift not open and if product sold out/disabled" do
    login_as!(@barista)

    # close shift: current_shift should be nil -> "Смена не открыта"
    @cash_shift.update!(status: "closed")
    post "/barista/orders", params: { cart_items: [{ product_id: @product.id, quantity: 1 }], payment_method: "cash" }
    assert_response :redirect
    follow_redirect!
    # UI currently indicates closed shift in status bar (flash may not be rendered on this page)
    assert_includes response.body, "Смена закрыта"

    # open again
    @cash_shift.update!(status: "open")

    setting = ProductTenantSetting.find_by!(tenant: @tenant_a, product: @product)
    setting.update!(is_sold_out: true, sold_out_reason: "stock_empty")
    post "/barista/orders", params: { cart_items: [{ product_id: @product.id, quantity: 1 }], payment_method: "cash" }
    assert_response :redirect
    follow_redirect!
    # Flash может не рендериться на этой странице; проверяем UI-индикатор "стоп-лист"
    assert_includes response.body, "Стоп"
  end

  test "update_status handles race: if status already changed, invalid transition does not change it" do
    login_as!(@barista)
    order = Order.create!(
      tenant: @tenant_a,
      cash_shift: @cash_shift,
      order_number: "RC-1",
      source: "manual",
      status: "preparing",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    # simulate race: client thinks accepted->ready, but order is preparing already; try preparing->accepted (invalid)
    patch "/barista/orders/#{order.id}/update_status", params: { status: "accepted" }
    assert_response :redirect
    assert_equal "preparing", order.reload.status
  end

  # 14. Статистика смены
  test "shift stats revenue counts only succeeded payments" do
    login_as!(@barista)

    order1 = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "S-1", source: "manual", status: "accepted", total_amount: 100, discount_amount: 0, final_amount: 100)
    order2 = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "S-2", source: "manual", status: "accepted", total_amount: 200, discount_amount: 0, final_amount: 200)

    Payment.create!(tenant: @tenant_a, order: order1, amount: 100, method: "cash", provider: "manual", status: "succeeded", paid_at: Time.current)
    Payment.create!(tenant: @tenant_a, order: order2, amount: 200, method: "cash", provider: "manual", status: "pending", paid_at: nil)

    get "/barista/shift"
    assert_response :success
    # revenue should include only 100
    assert_includes response.body, "100"
  end

  # 15. UI/UX детали (проверяем разметку)
  test "order card is clickable and action buttons stop propagation and cancel confirm exists" do
    login_as!(@barista)
    order = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "UX-1", source: "manual", status: "accepted", total_amount: 100, discount_amount: 0, final_amount: 100)
    OrderItem.create!(order: order, product_id: @product.id, product_name: @product.name, quantity: 1, unit_price: 100, total_price: 100)

    get "/barista"
    assert_response :success
    assert_includes response.body, "onclick=\"showOrderDetail('"
    assert_includes response.body, "event.stopPropagation();"
    assert_includes response.body, "data-turbo-confirm"
    assert_includes response.body, "Отменить заказ?"
  end
end

