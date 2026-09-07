# frozen_string_literal: true

module Payments
  # Нижняя граница суммы к оплате (Т-Банк Init: от 1000 коп. = 10 ₽).
  module AmountLimits
    MIN_CHARGE_RUB = 10
    MIN_CHARGE_KOPECKS = (MIN_CHARGE_RUB * 100).freeze

    module_function

    def below_minimum?(amount_rub)
      BigDecimal(amount_rub.to_s) < MIN_CHARGE_RUB
    end

    def ensure_chargeable!(amount_rub)
      return unless below_minimum?(amount_rub)

      raise TooSmall, "Минимальная сумма оплаты — #{MIN_CHARGE_RUB} ₽"
    end

    class TooSmall < StandardError; end
  end
end
