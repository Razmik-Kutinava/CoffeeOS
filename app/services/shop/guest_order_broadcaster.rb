# frozen_string_literal: true

module Shop
  # WebSocket + FCM + Apple Wallet (#38) + enqueue OrderReadyCascadeJob (#39) для mobile.
  class GuestOrderBroadcaster
    def self.call(order:, old_status: nil)
      return unless order.source == "mobile"

      payload = {
        type: "status_changed",
        order_id: order.id,
        status: order.status,
        can_cancel: order.guest_can_cancel?,
        payment_settled: !order.pending_payment?,
        old_status: old_status,
        order_number: order.order_number
      }
      payload.merge!(Shop::OrderCancellationPresenter.meta_for(order)) if order.cancelled?

      begin
        Shop::GuestOrderChannel.broadcast_to(order, payload)
      rescue StandardError => e
        Rails.logger.warn("[Shop::GuestOrderBroadcaster] cable unavailable: #{e.class} #{e.message}")
      end

      Shop::OrderStatusPushNotifier.call(order: order, old_status: old_status)
      enqueue_wallet_pass_update!(order)
      enqueue_ready_cascade!(order)
    end

    def self.enqueue_wallet_pass_update!(order)
      return unless OrderWalletPass.exists?(order_id: order.id)

      Shop::AppleWallet::PassUpdateJob.perform_later(order.id)
    end
    private_class_method :enqueue_wallet_pass_update!

    # #39: платные каналы после бесплатных WS/Push/Wallet.
    # Group 4: grace → re-check presence в job; SMS только если всё ещё offline.
    # #82: сброс stale order:{id}:online (убитый WS без unsubscribe).
    # #82 Патч_1: begin_sms_grace! — Cable reconnect внутри grace не даёт ложный SMS skipped.
    # Live Cable при hide-on-ready снимает подписку → unsubscribed → offline до SMS_GRACE.
    # TASK_93-J: wait = SMS_GRACE + BUFFER (избежать race expiry vs job start).
    def self.enqueue_ready_cascade!(order)
      return unless order.ready?

      Shop::OrderReadyPresence.begin_sms_grace!(order.id)
      wait = Shop::OrderReadyCascadeJob::SMS_GRACE + Shop::OrderReadyCascadeJob::SMS_GRACE_JOB_BUFFER
      Shop::OrderReadyCascadeJob
        .set(wait: wait)
        .perform_later(order.id)
    end
    private_class_method :enqueue_ready_cascade!
  end
end
