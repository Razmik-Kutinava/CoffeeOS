# frozen_string_literal: true

module Shop
  # Push при смене статуса mobile-заказа (B1.1 + #38 FCM enrich).
  class OrderStatusPushNotifier
    # B2.1 — тексты при смене статуса баристой (accepted→preparing, preparing→ready).
    BARISTA_TRANSITION_BODIES = {
      %w[accepted preparing] => "Ваш заказ начали готовить",
      %w[preparing ready] => "Заказ готов, забирайте!"
    }.freeze

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

      # #35 C1/C2 + B3: ready — claim once, затем ReadyPushJob (Wallet + FCM)
      if @order.ready?
        # #35 C1: claim делает сам ReadyPushJob (атомарно). Нотификатор лишь избегает enqueue,
        #        если уже готово (`ready_notified_at` проставлен).
        return if @order.ready_notified_at.present?

        Shop::ReadyPushJob.perform_later(@order.id, @old_status.to_s.presence || "preparing")
        return
      end

      meta = enriched_meta!
      return if meta == :aborted

      title = TITLES[@order.status] || "Статус заказа"
      body = compose_body(meta)
      payload = {
        "order_id" => @order.id,
        "status" => @order.status,
        "order_number" => @order.order_number
      }
      if meta
        payload["tag"] = meta[:tag]
        payload["actions"] = meta[:actions]
        payload["progress"] = meta[:progress]
      end

      notification = PushNotification.create!(
        customer_id: customer.id,
        tenant_id: @order.tenant_id,
        notification_type: "order_status",
        title: title,
        body: body,
        payload: payload,
        status: :pending
      )

      Shop::SendPushNotificationJob.perform_later(notification.id)
    rescue StandardError => e
      Rails.logger.warn("[Shop::OrderStatusPushNotifier] #{e.class}: #{e.message}")
    end

    private

    # :aborted — ошибка enrich; nil — статус вне матрицы (legacy); Hash — enrich ok
    def enriched_meta!
      return nil unless Shop::OrderStatusPushPayload.enrichable?(@order)

      Shop::OrderStatusPushPayload.build!(order: @order)
    rescue Shop::OrderStatusPushPayload::Error => e
      Rails.logger.warn("[Shop::OrderStatusPushNotifier] payload #{e.class}: #{e.message}")
      :aborted
    end

    def compose_body(meta)
      text = body_for_status
      return text unless meta.is_a?(Hash)

      "#{meta[:progress]} #{text}"
    end

    def body_for_status
      transition_body = BARISTA_TRANSITION_BODIES[[@old_status.to_s, @order.status.to_s]]
      return transition_body if transition_body.present?

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
