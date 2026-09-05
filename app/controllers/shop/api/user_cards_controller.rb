# frozen_string_literal: true

module Shop
  module Api
    # GET /shop/api/user/cards — список UserCards (макет 1000008925).
    class UserCardsController < Shop::Api::BaseController
      def index
        cid = resolve_customer_id!
        if cid.blank?
          return render json: {
            primary: nil,
            cards: [],
            sbp_accounts: [],
            has_sbp_account: false,
            growth_promo: { eligible: false, amount_rub: Payments::GrowthPromo.promo_amount_rub(@shop_tenant), step_up_required: false }
          }
        end

        cards = MobilePaymentMethod.for_customer(cid).select { |c| card_exp_valid?(c.card_expires_at) }
        primary = cards.find(&:is_default?) || cards.first
        sbp_accounts = MobilePaymentMethod.sbp_for_customer(cid)

        render json: {
          primary: Shop::SavedCardJson.serialize(primary),
          cards: cards.map { |c| Shop::SavedCardJson.serialize(c) },
          sbp_accounts: sbp_accounts.map { |a| Shop::SavedCardJson.serialize_sbp(a) },
          has_sbp_account: sbp_accounts.any?,
          growth_promo: growth_promo_payload(cid)
        }
      end

      private

      def growth_promo_payload(customer_id)
        customer = MobileCustomer.find_by(id: customer_id)
        eligible = Payments::GrowthPromo.eligible?(
          tenant: @shop_tenant,
          customer: customer,
          bind_requested: true
        )
        {
          eligible: eligible,
          amount_rub: Payments::GrowthPromo.promo_amount_rub(@shop_tenant),
          step_up_required: Payments::BindingStepUp.requires_step_up?(customer)
        }
      end

      def resolve_customer_id!
        Shop::CustomerSession.customer_id(session, @shop_tenant.id)
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
