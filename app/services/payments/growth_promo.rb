# frozen_string_literal: true

module Payments
  # #75: промо 11₽ при сохранении способа оплаты (единый payment object, без отдельной verification).
  class GrowthPromo
    AMOUNT_RUB = 11

    def self.eligible?(tenant:, customer:, bind_requested:, method_hash: nil)
      return false unless ActiveModel::Type::Boolean.new.cast(bind_requested)
      return false if tenant.blank? || customer.blank?
      return false unless point_allows_promo?(tenant)
      return false if CardBindingAttempt.growth_used_for_phone?(customer.phone)
      return false if CardBindingAttempt.growth_used_for_method_hash?(method_hash)

      true
    end

    def self.charge_amount(cart_total:, tenant:, customer:, bind_requested:, method_hash: nil)
      total = cart_total.to_d
      if eligible?(tenant: tenant, customer: customer, bind_requested: bind_requested, method_hash: method_hash)
        AMOUNT_RUB.to_d
      else
        total
      end
    end

    def self.mark_used!(phone:, method_hash:, method_type:, customer_id:, tenant_id:)
      CardBindingAttempt.record!(
        method_type: method_type,
        method_hash: method_hash,
        phone: phone,
        account_id: customer_id,
        point_id: tenant_id,
        result: "ok",
        is_growth_event: true
      )
    end

    def self.point_allows_promo?(tenant)
      # Пока нет флага на точке — промо доступно (выключение точки = отдельный follow-up).
      tenant.present?
    end
    private_class_method :point_allows_promo?
  end
end
