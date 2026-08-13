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

  # 1. Табло заказов (Dashboard): 6 слотов + подписка Turbo Streams
  test "dashboard renders six slot board and turbo stream subscription" do
    login_as!(@barista)
    get "/barista"
    assert_response :success

    assert_includes response.body, 'id="barista-board-slots"'
    assert_includes response.body, "board-grid"
    assert_includes response.body, "board-slot-empty"
    assert_includes response.body, "Коснитесь карточки"
    refute_includes response.body, "id=\"kanban\""
    assert_includes response.body, "turbo-cable-stream-source"
  end

  # 2. Управление заказами: отмена доступна и меняет статус
  test "barista can cancel accepted order with reason and code" do
    login_as!(@barista)

    ensure_order_cancel_reason!(
      code: "barista_cancel",
      name: "Отменено баристой",
      description: "Отмена заказа баристой"
    )

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

  # 6. Меню (W1.4): sold_out скрыт — как на витрине (products_scope)
  test "menu hides sold out product aligned with vitrina" do
    login_as!(@barista)
    ProductTenantSetting.find_by!(tenant: @tenant_a, product: @product).update!(is_sold_out: true, sold_out_reason: "stock_empty")

    get "/barista/menu"
    assert_response :success
    refute_includes response.body, @product.name
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
  test "dashboard with no orders shows six empty slots" do
    login_as!(@barista)
    get "/barista"
    assert_response :success
    assert_select "#barista-board-slots .board-slot-empty", 6
  end

  test "dashboard shows at most six FIFO slots when more than fifty accepted in scope" do
    login_as!(@barista)
    queue_base = @cash_shift.opened_at
    60.times do |i|
      Order.create!(
        tenant: @tenant_a,
        cash_shift: @cash_shift,
        order_number: "L-#{i}",
        source: "manual",
        status: "accepted",
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100,
        created_at: queue_base + i.seconds
      )
    end

    vitrina_newest = Order.create!(
      tenant: @tenant_a,
      cash_shift: nil,
      order_number: "VITRINA-NEW",
      source: "mobile",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: queue_base + 90.seconds
    )

    get "/barista"
    assert_response :success
    assert_select "#count-accepted", text: "61"
    assert_select "#total-on-board", text: "61"
    assert_select "#barista-board-slots .board-slot-card", 6
    %w[L-0 L-1 L-2 L-3 L-4 L-5].each do |num|
      assert_includes response.body, num
    end
    refute_includes response.body, "L-6"
    refute_includes response.body, "VITRINA-NEW"
    refute_includes response.body, %(id="order_#{vitrina_newest.id}")
  end

  test "revision board card shows first product line only" do
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
    assert_includes response.body, "board-slot-product"
    assert_includes response.body, "P0"
    refute_includes response.body, "P4"
    refute_includes response.body, "...еще"
  end

  # 11. B2.1 ревизия — таймеры на карточке убраны (макет заказчика)
  test "revision board card has no per-card timer markup" do
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

    get "/barista"
    assert_response :success
    assert_select ".board-slot-card--accepted"
    assert_select ".board-slot-card .order-timer", false
    assert_select ".board-slot-card [data-controller~='order-timer']", false
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

    CashShift.where(tenant_id: @tenant_a.id, status: "open").update_all(status: "closed", closed_at: Time.current)
    assert_nil CashShift.find_by(tenant_id: @tenant_a.id, status: "open")

    post "/barista/orders", params: { cart_items: [ { product_id: @product.id, quantity: 1 } ], payment_method: "cash" }
    assert_redirected_to barista_new_order_path
    assert_includes flash[:alert].to_s, "Смена не открыта"

    follow_redirect!
    assert_includes response.body, "Смена закрыта"

    @cash_shift.reload.update!(status: "open", closed_at: nil, closed_by_id: nil)

    setting = ProductTenantSetting.find_by!(tenant: @tenant_a, product: @product)
    setting.update!(is_sold_out: true, sold_out_reason: "stock_empty")

    assert_no_difference -> { Order.count } do
      post "/barista/orders", params: { cart_items: [ { product_id: @product.id, quantity: 1 } ], payment_method: "cash" }
    end
    assert_redirected_to barista_new_order_path
    assert_match(/недоступен|закончился/i, flash[:alert].to_s)
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

  # 15. B2.1 — карточка табло: цвет, кнопка 80px, модификаторы
  test "order card renders B2.1 stage1 layout with status button and modifiers" do
    login_as!(@barista)
    order = Order.create!(tenant: @tenant_a, cash_shift: @cash_shift, order_number: "UX-1", source: "manual", status: "accepted", total_amount: 100, discount_amount: 0, final_amount: 100)
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 100,
      total_price: 100,
      modifier_options: {
        "selected_modifiers" => [ { "name" => "Со льдом" } ],
        "removed_modifiers" => [ { "name" => "Сахар" } ]
      }
    )

    get "/barista"
    assert_response :success
    assert_includes response.body, "board-slot-card--accepted"
    assert_includes response.body, "board-slot-tap"
    assert_includes response.body, "Табло заказа"
    assert_includes response.body, "board-slot-modifier"
    assert_includes response.body, "+ Со льдом"
    assert_includes response.body, 'onclick="event.stopPropagation();"'
    refute_includes response.body, "Принять →"
    assert_includes response.body, "order-card-cancel-overlay"
    assert_includes response.body, "СТОП! ЗАКАЗ ОТМЕНЁН"
    assert_includes response.body, "ПОДТВЕРДИТЬ ОТМЕНУ"
    assert_includes response.body, "order-card-cancel"
  end

  # 16. B2.1 этап 2 — FIFO и без drag-hint
  test "dashboard FIFO accepted orders oldest first and no drag hint" do
    login_as!(@barista)

    older = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "FIFO-OLD",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: 3.hours.ago
    )
    newer = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "FIFO-NEW",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: 1.hour.ago
    )

    get "/barista"
    assert_response :success
    assert_operator response.body.index("FIFO-OLD"), :<, response.body.index("FIFO-NEW")
    refute_includes response.body, "Перетащите карточку"
    assert_includes response.body, "Коснитесь карточки"
    assert_includes response.body, 'id="barista-board-slots"'
  end

  test "update_status turbo resyncs source and target columns FIFO" do
    login_as!(@barista)

    order = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "FIFO-MOVE",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: 2.hours.ago
    )

    patch "/barista/orders/#{order.id}/update_status",
          params: { status: "preparing" },
          headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "preparing", order.reload.status
    assert_includes response.body, 'target="barista-board-slots"'
    assert_includes response.body, "board-slot-card--preparing"
    assert_includes response.body, "FIFO-MOVE"
  end

  # 17. B2.1 ревизия R3 — tap белый (accepted) → жёлтый (preparing)
  test "revision tap accepted to preparing replaces board slots via turbo" do
    login_as!(@barista)

    order = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "R3-TAP-1",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100
    )

    patch "/barista/orders/#{order.id}/update_status",
          params: { status: "preparing" },
          headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "preparing", order.reload.status
    assert_includes response.body, 'target="barista-board-slots"'
    assert_includes response.body, "board-slot-card--preparing"
    assert_includes response.body, "R3-TAP-1"
    refute_includes response.body, "board-slot-card--accepted"
  end

  # 18. B2.1 ревизия R3 — tap жёлтый → ready убирает карточку с табло (6 слотов)
  test "revision tap preparing to ready removes order from board slots" do
    login_as!(@barista)

    order = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "R3-GONE",
      source: "manual", status: "preparing",
      total_amount: 100, discount_amount: 0, final_amount: 100
    )

    patch "/barista/orders/#{order.id}/update_status",
          params: { status: "ready" },
          headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "ready", order.reload.status
    assert_includes response.body, 'target="barista-board-slots"'
    refute_includes response.body, "R3-GONE"
    refute_includes response.body, %(id="order_#{order.id}")
    assert_includes response.body, "board-slot-empty"
  end

  # 19. B2.1 этап 4 — отмена: overlay + resync колонки
  test "cancel turbo resyncs column and removes order from board" do
    login_as!(@barista)

    ensure_order_cancel_reason!(
      code: "barista_cancel",
      name: "Отменено баристой",
      description: "Отмена заказа баристой"
    )

    order = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "B21-CANCEL",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100
    )
    keep = Order.create!(
      tenant: @tenant_a, cash_shift: @cash_shift, order_number: "B21-KEEP",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100,
      created_at: 1.hour.ago
    )

    post "/barista/orders/#{order.id}/cancel",
         params: { reason: "Отменено баристой", reason_code: "barista_cancel" },
         headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "cancelled", order.reload.status
    assert_includes response.body, 'target="barista-board-slots"'
    refute_includes response.body, "B21-CANCEL"
    assert_includes response.body, "B21-KEEP"
    assert_not_nil keep.id
  end
end
