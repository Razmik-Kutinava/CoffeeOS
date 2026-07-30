# frozen_string_literal: true

module Shop
  module Api
    # GET /shop/api/user/cards — список UserCards (макет 1000008925).
    class UserCardsController < Shop::Api::BaseController
      def index
        cid = resolve_customer_id!
        if cid.blank?
          return render json: { primary: nil, cards: [], sbp_accounts: [], has_sbp_account: false }
        end

        cards = MobilePaymentMethod.for_customer(cid).select { |c| card_exp_valid?(c.card_expires_at) }
        primary = cards.find(&:is_default?) || cards.first
        sbp_accounts = MobilePaymentMethod.sbp_for_customer(cid)

        render json: {
          primary: Shop::SavedCardJson.serialize(primary),
          cards: cards.map { |c| Shop::SavedCardJson.serialize(c) },
          sbp_accounts: sbp_accounts.map { |a| Shop::SavedCardJson.serialize_sbp(a) },
          has_sbp_account: sbp_accounts.any?
        }
      end

      private

      def resolve_customer_id!
        Shop::GuestCustomerResolver.call(
          session: session,
          tenant_id: @shop_tenant.id,
          email: params[:email]
        )
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
