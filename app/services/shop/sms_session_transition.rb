# frozen_string_literal: true

module Shop
  # TASK_117: SMS short-link may not overwrite another guest in the same tenant
  # without explicit confirm. Pending token carries order ownership; confirm binds
  # + clears cart (R2); decline leaves session untouched.
  class SmsSessionTransition
    PURPOSE = "shop_sms_session_transition"
    TTL = 30.minutes

    class << self
      def conflict?(session, order)
        cid = CustomerSession.customer_id(session, order.tenant_id)
        cid.present? && cid.to_s != order.customer_id.to_s
      end

      def pending_token_for(order)
        verifier.generate(
          {
            oid: order.id.to_s,
            tid: order.tenant_id.to_s,
            cid: order.customer_id.to_s
          },
          expires_in: TTL
        )
      end

      def order_from_pending!(token)
        payload = verify_payload(token)
        return nil unless payload

        Order.where(
          id: payload[:oid],
          tenant_id: payload[:tid],
          customer_id: payload[:cid],
          source: :mobile
        ).first
      end

      def confirm!(session, token:)
        order = order_from_pending!(token)
        return nil unless order

        reconnect = GuestOrderReconnect.token_for(order)
        bound = GuestOrderReconnect.bind!(
          session,
          tenant_id: order.tenant_id,
          order_id: order.id,
          token: reconnect
        )
        return nil unless bound

        CartService.new(session, order.tenant_id).clear!
        bound
      end

      def decline!(session, token:)
        # Validate token so forged decline cannot probe; session unchanged.
        order_from_pending!(token).present?
      end

      private

      def verify_payload(token)
        return nil if token.blank?

        verifier.verify(token.to_s).symbolize_keys
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end

      def verifier
        Rails.application.message_verifier(PURPOSE)
      end
    end
  end
end
