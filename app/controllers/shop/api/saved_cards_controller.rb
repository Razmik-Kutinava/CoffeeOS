# frozen_string_literal: true

module Shop
  module Api
    class SavedCardsController < Shop::Api::BaseController
      def index
        cid = resolve_customer_id!
        if cid.blank?
          return render json: { primary: nil, cards: [] }
        end

        cards = MobilePaymentMethod.for_customer(cid).to_a
        primary = cards.find(&:is_default?) || cards.first

        render json: {
          primary: serialize_card(primary),
          cards: cards.map { |c| serialize_card(c) }
        }
      end

      private

      def resolve_customer_id!
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        return cid if cid.present?

        email = Shop::EmailVerificationSession.normalize(params[:email])
        return nil if email.blank?

        verified = Shop::EmailVerification.verified_email(
          session: session,
          tenant_id: @shop_tenant.id,
          session_id: request.session.id.to_s,
          email: email
        )
        return nil unless verified == email

        customer = MobileCustomer.find_by(email: email)
        return nil unless customer

        Shop::CustomerSession.set_customer_id!(session, @shop_tenant.id, customer.id)
        customer.id.to_s
      end

      def serialize_card(card)
        return nil unless card

        {
          id: card.id,
          payment_system: card.card_brand,
          masked_pan: card.card_masked,
          is_primary: card.is_default?,
          last_used_at: card.last_used_at&.iso8601
        }
      end
    end
  end
end
