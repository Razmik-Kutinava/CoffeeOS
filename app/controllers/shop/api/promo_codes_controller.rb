# frozen_string_literal: true

module Shop
  module Api
    class PromoCodesController < Shop::Api::BaseController
      def apply
        code = (params[:code] || params.dig(:promo_code)).to_s.upcase.strip
        order_total = params[:order_total].to_f

        if code.blank?
          return render json: { valid: false, error: "Введите промокод" }, status: :unprocessable_entity
        end

        # BUG-004 FIX: Промокоды не реализованы — отклоняем любой код до появления модели PromoCode.
        # Раньше любой непустой код давал 10% скидку, что приводило к прямым финансовым потерям.
        render json: { valid: false, error: "Промокоды временно недоступны" }, status: :unprocessable_entity
      end
    end
  end
end
