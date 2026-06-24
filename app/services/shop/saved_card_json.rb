# frozen_string_literal: true

module Shop
  module SavedCardJson
    module_function

    def serialize(card)
      return nil unless card

      {
        id: card.id,
        payment_system: card.card_brand,
        masked_pan: card.card_masked,
        pan: card.pan_display,
        exp_date: card.card_expires_at,
        card_type: card.card_brand,
        bank_card_id: card.bank_card_id,
        is_primary: card.is_default?,
        last_used_at: card.last_used_at&.iso8601
      }.compact
    end
  end
end
