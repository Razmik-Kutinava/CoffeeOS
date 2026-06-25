# frozen_string_literal: true

require "test_helper"

# B1.1 критерии приёмки — docs/.../customer_tasks/B1_1_order_status_progress.md
class Shop::OrderStatusAcceptanceCbrTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 199)
    @email = "b11-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  # Критерий: 4 шага прогресс-бара (иконки, порядок, цвета в коде)
  test "b11_01 progress bar four steps and brand colors in vitrina" do
    progress = File.read(Rails.root.join("app/frontend/lib/orderStatusProgress.js"))
    screen = vitrina_source("routes/OrderStatus.svelte")

    assert_includes progress, "Принят"
    assert_includes progress, "Оплачен"
    assert_includes progress, "Готовится"
    assert_includes progress, "Готов"
    assert_includes progress, "🔔"
    assert_includes progress, "ETA_SUBTITLE"
    assert_includes screen, "#ff8c42"
    assert_includes screen, "#e8f5e9"
    assert_includes screen, "#4caf50"
    assert_includes screen, "#757575"
    assert_includes screen, "progress-steps"
    assert_includes screen, "status-subtitle"
    assert_includes screen, "Состав заказа"
    assert_includes screen, "Самовывоз"
  end

  # Критерий: маршрут /order/:id и редирект после cash checkout
  test "b11_02 order status route and checkout redirect" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    checkout = vitrina_source("routes/Checkout.svelte")

    assert_includes app, '"/order/:id"'
    assert_includes checkout, "push(`/order/${orderId}`)"
  end

  # Критерий: API отдаёт поля для экрана статуса
  test "b11_03 order show json includes status screen fields" do
    order_id = create_cash_order!

    get "/shop/api/orders/#{order_id}", headers: shop_tenant_headers(@tenant.id)

    assert_response :success
    body = response.parsed_body
    assert body["order_number"].present?
    assert_equal true, body["can_cancel"]
    assert body.dig("tenant", "name").present?
    assert body["items"].is_a?(Array)
    assert_equal "accepted", body["status"]
    assert body["reconnect_token"].present?
  end

  # Критерий: live update — cable channel + broadcaster
  test "b11_04 websocket stack present for guest order" do
    assert_path_exists Rails.root.join("app/channels/shop/guest_order_channel.rb")
    assert_path_exists Rails.root.join("app/frontend/lib/shopOrderCable.js")

    screen = vitrina_source("routes/OrderStatus.svelte")
    cable = File.read(Rails.root.join("app/frontend/lib/shopOrderCable.js"))
    channel = File.read(Rails.root.join("app/channels/shop/guest_order_channel.rb"))
    assert_includes screen, "subscribeGuestOrderStatus"
    assert_includes screen, "Обновление статуса..."
    assert_includes cable, "reconnect_token"
    assert_includes channel, "customer_id"
  end

  # Критерий: отмена гостем + запрет на preparing
  test "b11_05 guest cancel and deny on preparing" do
    order_id = create_cash_order!

    post "/shop/api/orders/#{order_id}/cancel", headers: shop_tenant_headers(@tenant.id)
    assert_response :success
    assert_equal "cancelled", response.parsed_body["status"]
    assert_equal "guest", response.parsed_body["cancelled_by"]

    order_id2 = create_cash_order!
    Order.find(order_id2).update!(status: :preparing)

    post "/shop/api/orders/#{order_id2}/cancel", headers: shop_tenant_headers(@tenant.id)
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "уже готовится"
  end

  # Критерий: отмена баристой — отдельное сообщение в API
  test "b11_06 staff cancel message in order json" do
    order_id = create_cash_order!
    order = Order.find(order_id)
    barista = create_user!(tenant: @tenant, role_codes: ["barista"])

    Barista::OrderCancellationService.new(
      order: order,
      actor: barista,
      tenant_id: @tenant.id,
      user_id: barista.id,
      reason: "Нет молока"
    ).call!

    get "/shop/api/orders/#{order_id}", headers: shop_tenant_headers(@tenant.id)

    assert_response :success
    body = response.parsed_body
    assert_equal "staff", body["cancelled_by"]
    assert_includes body["cancel_message"], "исполнителем"
  end

  # Критерий: история заказов → экран статуса
  test "b11_07 orders list links to order status screen" do
    orders = vitrina_source("routes/Orders.svelte")
    assert_includes orders, "push(`/order/${order.id}`)"
  end

  # Критерий: push при смене статуса
  test "b11_08 push notifier on status change" do
    assert_path_exists Rails.root.join("app/services/shop/order_status_push_notifier.rb")
    assert_path_exists Rails.root.join("app/jobs/shop/send_push_notification_job.rb")
    assert_path_exists Rails.root.join("app/controllers/shop/api/push_controller.rb")
    broadcaster = File.read(Rails.root.join("app/services/shop/guest_order_broadcaster.rb"))
    screen = vitrina_source("routes/OrderStatus.svelte")
    push_js = File.read(Rails.root.join("app/frontend/lib/firebasePush.js"))
    assert_includes broadcaster, "OrderStatusPushNotifier"
    assert_includes screen, "Разрешить уведомления"
    assert_includes push_js, "/push/register"
  end

  private

  def vitrina_source(rel)
    File.read(Rails.root.join("app/frontend", rel))
  end

  def create_cash_order!
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, name: "B11 QA", payment_method: "cash"),
      as: :json
    assert_response :success
    response.parsed_body["order_id"]
  end
end
