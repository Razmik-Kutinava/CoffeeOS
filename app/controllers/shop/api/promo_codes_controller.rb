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

        # Заглушка: любой непустой код даёт 10% (как в баристе до модели PromoCode)
        discount = (BigDecimal(order_total.to_s) * 0.1).round(2).to_f
        final_total = [ order_total - discount, 0.0 ].max

        render json: { valid: true, discount: discount, final_total: final_total }
      end
    end
  end
end
