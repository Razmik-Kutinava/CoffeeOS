# frozen_string_literal: true

module Shop
  # Восстановление привязки гостя к заказу после редиректа на Т-Банк (сессия/cookie могут «отстать»).
  class GuestOrderReconnect
    PURPOSE = "shop_guest_order"

    class << self
      def token_for(order)
        verifier.generate(
          { oid: order.id.to_s, cid: order.customer_id.to_s, tid: order.tenant_id.to_s },
          expires_in: 24.hours
        )
      end

      def bind!(session, tenant_id:, order_id:, token:)
        order = order_for_cable!(order_id: order_id, tenant_id: tenant_id, token: token)
        return nil unless order

        Shop::CustomerSession.set_customer_id!(session, tenant_id, order.customer_id)
        Shop::PendingOrderSession.set!(session, tenant_id, order.id) if order.pending_payment?
        order
      end

      def order_for_cable!(order_id:, tenant_id:, token: nil, customer_id: nil)
        order = Order.where(id: order_id, tenant_id: tenant_id, source: :mobile).first
        return nil unless order

        if token.present?
          return order if token_matches_order?(order, tenant_id: tenant_id, token: token)
          # Stale token from another checkout — fall through to customer session below.
        end

        if customer_id.present? && order.customer_id.present? && order.customer_id.to_s == customer_id.to_s
          return order
        end

        nil
      end

      def token_matches_order?(order, tenant_id:, token:)
        payload = verifier.verify(token).symbolize_keys
        payload[:oid].to_s == order.id.to_s &&
          payload[:cid].to_s == order.customer_id.to_s &&
          payload[:tid].to_s == tenant_id.to_s
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        false
      end

      def verifier
        Rails.application.message_verifier(PURPOSE)
      end
    end
  end
end
