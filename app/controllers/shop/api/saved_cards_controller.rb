# frozen_string_literal: true

module Shop
  module Api
    class SavedCardsController < Shop::Api::BaseController
      def index
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
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
