# frozen_string_literal: true

module Shop
  module Api
    # GET /shop/api/user/cards — список UserCards (макет 1000008925).
    class UserCardsController < Shop::Api::BaseController
      def index
        cid = resolve_customer_id!
        if cid.blank?
          return render json: { primary: nil, cards: [] }
        end

        cards = MobilePaymentMethod.for_customer(cid).select { |c| card_exp_valid?(c.card_expires_at) }
        primary = cards.find(&:is_default?) || cards.first

        render json: {
          primary: Shop::SavedCardJson.serialize(primary),
          cards: cards.map { |c| Shop::SavedCardJson.serialize(c) }
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

      # Карта валидна до конца месяца exp_date (ММ/ГГ или MMYY).
      def card_exp_valid?(exp)
        digits = exp.to_s.gsub(/\D/, "")
        return true if digits.length != 4

        month = digits[0, 2].to_i
        year = 2000 + digits[2, 2].to_i
        return false unless (1..12).cover?(month)

        Date.new(year, month, -1) >= Date.current
      rescue ArgumentError
        false
      end
    end
  end
end
