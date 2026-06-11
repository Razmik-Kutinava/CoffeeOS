# frozen_string_literal: true

require "test_helper"

class Barista::OrderStatusUpdateServiceTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @user = create_user!(tenant: @tenant, role_codes: %w[barista])
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @user)
    @order = Order.create!(
      tenant: @tenant,
      cash_shift: @shift,
      order_number: "ST-1",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    Current.tenant_id = @tenant.id
  end

  teardown { Current.reset }

  test "updates status and creates status log" do
    result = Barista::OrderStatusUpdateService.new(
      order: @order,
      new_status: "preparing",
      user_id: @user.id,
      comment: "В работу"
    ).call!

    assert_equal "preparing", result[:order].status
    assert_equal "accepted", result[:old_status]
    log = OrderStatusLog.order(created_at: :desc).first
    assert_equal "preparing", log.status_to
    assert_equal "В работу", log.comment
  end

  test "mobile order preparing triggers b21 guest push body" do
    customer = create_mobile_customer!(phone: "+79007778899", email: "b21-#{SecureRandom.hex(3)}@example.com")
    customer.update!(push_enabled: true, push_token: "fcm-b21-token")
    mobile_order = Order.create!(
      tenant: @tenant,
      cash_shift: @shift,
      customer_id: customer.id,
      order_number: "B21-M1",
      source: :mobile,
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    assert_enqueued_with(job: Shop::SendPushNotificationJob) do
      Barista::OrderStatusUpdateService.new(
        order: mobile_order,
        new_status: "preparing",
        user_id: @user.id
      ).call!
    end

    notification = PushNotification.order(created_at: :desc).first
    assert_equal "Ваш заказ начали готовить", notification.body
  end

  test "rejects invalid transition" do
    assert_raises(Barista::OrderStatusUpdateService::OrderStatusUpdateError) do
      Barista::OrderStatusUpdateService.new(
        order: @order,
        new_status: "issued",
        user_id: @user.id
      ).call!
    end
    assert_equal "accepted", @order.reload.status
  end
end
