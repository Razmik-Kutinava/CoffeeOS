# frozen_string_literal: true

module Shop
  # Push при смене статуса mobile-заказа (B1.1).
  class OrderStatusPushNotifier
    TITLES = {
      "pending_payment" => "Заказ принят",
      "accepted" => "Заказ оплачен",
      "preparing" => "Заказ готовится",
      "ready" => "Заказ готов",
      "cancelled" => "Заказ отменён"
    }.freeze

    def self.call(order:, old_status: nil)
      new(order: order, old_status: old_status).call
    end

    def initialize(order:, old_status: nil)
      @order = order
      @old_status = old_status
    end

    def call
      return unless @order.source == "mobile"
      return if @order.customer_id.blank?
      return if @old_status.present? && @old_status == @order.status

      customer = MobileCustomer.find_by(id: @order.customer_id)
      return unless customer&.push_enabled?
      return if customer.push_token.blank?

      title = TITLES[@order.status] || "Статус заказа"
      body = body_for_status

      notification = PushNotification.create!(
        customer_id: customer.id,
        tenant_id: @order.tenant_id,
        notification_type: "order_status",
        title: title,
        body: body,
        payload: {
          order_id: @order.id,
          status: @order.status,
          order_number: @order.order_number
        },
        status: :pending
      )

      Shop::SendPushNotificationJob.perform_later(notification.id)
    rescue StandardError => e
      Rails.logger.warn("[Shop::OrderStatusPushNotifier] #{e.class}: #{e.message}")
    end

    private

    def body_for_status
      number = @order.order_number.presence || @order.id.to_s.first(8)
      case @order.status
      when "ready"
        "Заказ ##{number} готов к выдаче"
      when "preparing"
        "Заказ ##{number} готовится"
      when "accepted"
        "Заказ ##{number} оплачен и принят в работу"
      when "cancelled"
        Shop::OrderCancellationPresenter.cancel_message_for(
          Shop::OrderCancellationPresenter.cancelled_by(@order)
        )
      else
        "Заказ ##{number}: #{@order.status}"
      end
    end
  end
end
