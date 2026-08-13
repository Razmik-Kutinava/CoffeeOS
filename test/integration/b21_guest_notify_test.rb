# frozen_string_literal: true

require "test_helper"

# B2.1 этап 3 — гость: WS + push тексты, связка бариста → гость
class B21GuestNotifyTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    @customer = create_mobile_customer!(phone: "+79008887766", email: "b21-guest-#{SecureRandom.hex(3)}@example.com")
    @customer.update!(push_enabled: true, push_token: "fcm-b21-guest")
    @order = Order.create!(
      tenant_id: @tenant.id,
      cash_shift: @shift,
      customer_id: @customer.id,
      customer_name: "B21 Guest",
      order_number: "B21-001",
      source: :mobile,
      status: :accepted,
      total_amount: 300,
      discount_amount: 0,
      final_amount: 300
    )
    Current.tenant_id = @tenant.id
    Current.user_id = @barista.id
  end

  teardown { Current.reset }

  test "b21_01 vitrina status screen has eta subtitle per b11 revision" do
    progress = File.read(Rails.root.join("app/frontend/lib/orderStatusProgress.js"))
    screen = File.read(Rails.root.join("app/frontend/routes/OrderStatus.svelte"))

    assert_includes progress, "Примерно 8–12 минут"
    assert_includes progress, "ETA_SUBTITLE"
    assert_includes screen, "status-subtitle"
  end

  test "b21_02 shop cable has ws retry policy" do
    cable = File.read(Rails.root.join("app/frontend/lib/shopOrderCable.js"))

    assert_includes cable, "WS_RETRY_INTERVAL_MS = 5000"
    assert_includes cable, "scheduleRetry"
  end

  test "b21_03 barista patch preparing enqueues guest push with b21 body" do
    login_as!(@barista)

    assert_enqueued_with(job: Shop::SendPushNotificationJob) do
      patch "/barista/orders/#{@order.id}/update_status",
            params: { status: "preparing" },
            headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "preparing", @order.reload.status

    notification = PushNotification.order(created_at: :desc).first
    assert_match(/\A🟩🟩⬜ Ваш заказ начали готовить\z/, notification.body)
  end
end
