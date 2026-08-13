# frozen_string_literal: true

require "test_helper"

class Shop::Api::OrdersGuestCancelTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
    @email = "guest-cancel-#{SecureRandom.hex(4)}@example.com"
  end

  test "POST cancel accepted order returns cancelled json with can_cancel false" do
    order_id = create_cash_order!

    post "/shop/api/orders/#{order_id}/cancel",
      headers: shop_tenant_headers(@tenant.id)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "cancelled", body["status"]
    assert_equal false, body["can_cancel"]
    assert_equal "guest", body["cancelled_by"]
    assert_equal "Заказ отменён", body["cancel_message"]
  end

  test "POST cancel preparing order returns 422" do
    order_id = create_cash_order!
    order = Order.find(order_id)
    order.update!(status: :preparing)

    post "/shop/api/orders/#{order_id}/cancel",
      headers: shop_tenant_headers(@tenant.id)

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["error"], "уже готовится"
  end

  # #40 Шаг 4 — API bypass: ready / issued → 422, платёж не меняется
  test "[TDD] POST cancel ready order returns 422 and leaves payment succeeded" do
    order_id = create_cash_order!
    order = Order.find(order_id)
    order.update!(status: :ready)
    payment = attach_succeeded_tbank_payment!(order)

    post "/shop/api/orders/#{order_id}/cancel",
      headers: shop_tenant_headers(@tenant.id)

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["error"], "уже готовится"
    assert_equal "ready", order.reload.status
    assert_equal "succeeded", payment.reload.status
  end

  test "[TDD] POST cancel issued order returns 422 and leaves payment succeeded" do
    order_id = create_cash_order!
    order = Order.find(order_id)
    order.update!(status: :issued)
    payment = attach_succeeded_tbank_payment!(order)

    post "/shop/api/orders/#{order_id}/cancel",
      headers: shop_tenant_headers(@tenant.id)

    assert_response :unprocessable_entity
    assert_equal "issued", order.reload.status
    assert_equal "succeeded", payment.reload.status
  end

  test "GET order after barista cancel shows staff message" do
    order_id = create_cash_order!
    order = Order.find(order_id)

    barista = create_user!(tenant: @tenant, role_codes: [ "barista" ])
    Barista::OrderCancellationService.new(
      order: order,
      actor: barista,
      tenant_id: @tenant.id,
      user_id: barista.id,
      reason: "Нет ингредиентов"
    ).call!

    get "/shop/api/orders/#{order_id}",
      headers: shop_tenant_headers(@tenant.id)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "cancelled", body["status"]
    assert_equal "staff", body["cancelled_by"]
    assert_includes body["cancel_message"], "исполнителем"
  end

  private

  def attach_succeeded_tbank_payment!(order)
    payment = order.payments.order(created_at: :desc).first
    if payment
      payment.update!(
        method: :card,
        provider: "tbank",
        provider_payment_id: "pay-block-#{SecureRandom.hex(3)}",
        status: :succeeded,
        paid_at: payment.paid_at || Time.current
      )
      payment
    else
      Payment.create!(
        order_id: order.id,
        tenant_id: @tenant.id,
        amount: order.final_amount,
        method: :card,
        provider: "tbank",
        provider_payment_id: "pay-block-#{SecureRandom.hex(3)}",
        status: :succeeded,
        paid_at: Time.current
      )
    end
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
      params: shop_order_params(email: @email, name: "Cancel Guest", payment_method: "cash"),
      as: :json
    assert_response :success
    JSON.parse(response.body)["order_id"]
  end
end
