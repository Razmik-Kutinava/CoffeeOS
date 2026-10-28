# frozen_string_literal: true

module Shop
  # #35 B3 — ready: Apple Wallet update + FCM. Любая ошибка Wallet/APNs → FCM всё равно уходит.
  # Не блокирует POS (async).
  # #38 — FCM body/payload с tag/actions/unicode progress.
  # TASK_92 Патч 1 — временная ошибка FCM: claim снимается, job ставится заново с backoff;
  # повтор сам, не retry_on: нужно передать исходное время claim (срок SMS-ссылки).
  class ReadyPushJob < ApplicationJob
    queue_as :default

    READY_BODY = "Ваш заказ готов, заберите на кассе!"
    TITLE = "Заказ готов"
    MAX_ATTEMPTS = 5
    RETRY_WAITS = [ 10.seconds, 30.seconds, 2.minutes, 5.minutes ].freeze

    def perform(order_id, old_status = "preparing", attempt: 1, claimed_at: nil)
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"
      return if order.customer_id.blank?

      with_order_tenant!(order) do
        customer = MobileCustomer.find_by(id: order.customer_id)
        return unless customer&.push_enabled? && customer.push_token.present?

        # #35 C1: атомарно фиксируем первую отправку и пропускаем любые дубли.
        return unless Shop::ReadyPushClaim.claim!(order, at: claimed_at)

        update_wallet!(order)
        deliver_fcm!(order, customer, old_status)
      rescue Shop::FcmClient::TransientError => e
        retry_later!(order, old_status, attempt, e)
      end
    end

    private

    def retry_later!(order, old_status, attempt, error)
      if attempt >= MAX_ATTEMPTS
        Rails.logger.warn(
          "[Shop::ReadyPushJob] order=#{order.id} gave up after #{attempt} attempts: #{error.message}"
        )
        return
      end

      claimed_at = order.ready_notified_at
      Shop::ReadyPushClaim.release!(order, claimed_at)
      self.class.set(wait: RETRY_WAITS.fetch(attempt - 1))
        .perform_later(order.id, old_status, attempt: attempt + 1, claimed_at: claimed_at)
    end

    def update_wallet!(order)
      pass = OrderWalletPass.find_by(order_id: order.id)
      # #38: PassUpdateJob may already bump to ready — skip duplicate revision.
      return if pass&.status_label.to_s == "ready"

      Shop::AppleWallet::PassUpdater.call!(order: order)
    rescue Shop::AppleWallet::UnavailableError => e
      Rails.logger.info("[Shop::ReadyPushJob] wallet fallback FCM-only: #{e.message}")
    rescue StandardError => e
      Rails.logger.warn("[Shop::ReadyPushJob] wallet update failed, FCM continues: #{e.class}: #{e.message}")
    end

    def deliver_fcm!(order, customer, _old_status)
      meta = Shop::OrderStatusPushPayload.build!(order: order)
      body = "#{meta[:progress]} #{READY_BODY}"

      notification = PushNotification.create!(
        customer_id: customer.id,
        tenant_id: order.tenant_id,
        notification_type: "order_status",
        title: TITLE,
        body: body,
        payload: {
          "order_id" => order.id,
          "status" => order.status,
          "order_number" => order.order_number,
          "channel" => "ready_push",
          "tag" => meta[:tag],
          "actions" => meta[:actions],
          "progress" => meta[:progress]
        },
        status: :pending
      )

      Shop::SendPushNotificationJob.perform_now(notification.id, raise_transient: true)
    rescue Shop::OrderStatusPushPayload::Error => e
      Rails.logger.warn("[Shop::ReadyPushJob] FCM payload #{e.class}: #{e.message}")
    rescue Shop::FcmClient::TransientError
      raise
    rescue StandardError => e
      fail_if_pending!(notification, e)
      raise
    end

    def fail_if_pending!(notification, error)
      return unless notification&.reload&.pending?

      notification.update!(status: :failed, error_message: "#{error.class}: #{error.message}")
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.warn("[Shop::ReadyPushJob] could not mark notification failed: #{e.class}: #{e.message}")
    end
  end
end
