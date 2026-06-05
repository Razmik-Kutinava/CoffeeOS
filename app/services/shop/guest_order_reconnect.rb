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
        order = Order.where(id: order_id, tenant_id: tenant_id, source: :mobile).first
        return nil unless order

        payload = verifier.verify(token).symbolize_keys
        return nil unless payload[:oid].to_s == order.id.to_s
        return nil unless payload[:cid].to_s == order.customer_id.to_s
        return nil unless payload[:tid].to_s == tenant_id.to_s

        Shop::CustomerSession.set_customer_id!(session, tenant_id, order.customer_id)
        Shop::PendingOrderSession.set!(session, tenant_id, order.id) if order.pending_payment?
        order
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end

      def verifier
        Rails.application.message_verifier(PURPOSE)
      end
    end
  end
end
