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
      update_wallet_pass_if_present!(order)
      enqueue_ready_cascade!(order)
    end

    def self.update_wallet_pass_if_present!(order)
      return unless OrderWalletPass.exists?(order_id: order.id)

      Shop::AppleWallet::PassUpdater.call!(order: order)
    rescue Shop::AppleWallet::UnavailableError, Shop::AppleWallet::GenerationError => e
      Rails.logger.warn("[Shop::GuestOrderBroadcaster] wallet update soft-fail: #{e.class} #{e.message}")
    rescue StandardError => e
      Rails.logger.warn("[Shop::GuestOrderBroadcaster] wallet update soft-fail: #{e.class} #{e.message}")
    end
    private_class_method :update_wallet_pass_if_present!

    # #39: платные каналы (TG→SMS) после бесплатных WS/Push/Wallet
    def self.enqueue_ready_cascade!(order)
      return unless order.ready?

      Shop::OrderReadyCascadeJob.perform_later(order.id)
    end
    private_class_method :enqueue_ready_cascade!
  end
end
