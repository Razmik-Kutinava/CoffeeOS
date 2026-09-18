# frozen_string_literal: true

module Shop
  module AppleWallet
    # TASK_93-J: APNs/PassUpdater off the request path (GuestOrderBroadcaster enqueue).
    class PassUpdateJob < ApplicationJob
      queue_as :default

      def perform(order_id)
        order = Order.find_by(id: order_id)
        return unless order

        with_order_tenant!(order) do
          return unless OrderWalletPass.exists?(order_id: order.id)

          Shop::AppleWallet::PassUpdater.call!(order: order)
        end
      rescue Shop::AppleWallet::UnavailableError, Shop::AppleWallet::GenerationError => e
        Rails.logger.warn("[Shop::AppleWallet::PassUpdateJob] soft-fail: #{e.class} #{e.message}")
      rescue StandardError => e
        Rails.logger.warn("[Shop::AppleWallet::PassUpdateJob] soft-fail: #{e.class} #{e.message}")
      end
    end
  end
end
