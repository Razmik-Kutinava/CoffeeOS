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

    # Суммы заказа с учётом chk_order_amounts: final = total_amount - discount_amount.
    # method_hash на этапе create НЕ принимаем от клиента — только phone-дедуп.
    def self.price!(subtotal:, discount:, tenant:, customer:, bind_requested:)
      sub = BigDecimal(subtotal.to_s)
      disc = BigDecimal(discount.to_s)
      cart = (sub - disc).round(2)

      if eligible?(tenant: tenant, customer: customer, bind_requested: bind_requested, method_hash: nil)
        final = AMOUNT_RUB.to_d
        {
          final_amount: final,
          discount_amount: (sub - final).round(2),
          growth_intent: true,
          cart_total_before: cart
        }
      else
        {
          final_amount: cart,
          discount_amount: disc,
          growth_intent: false,
          cart_total_before: cart
        }
      end
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

    # После успешной привязки при росте: серверный method_hash, без доверия клиенту.
    def self.consume_from_payment!(payment:, method_hash:, method_type:)
      return if payment.blank?
      return if method_hash.blank?

      data = payment.provider_data
      data = {} unless data.is_a?(Hash)
      return unless ActiveModel::Type::Boolean.new.cast(data["growth_promo_intent"])

      order = payment.order
      customer = order&.customer
      return if customer.blank?
      return if CardBindingAttempt.growth_used_for_phone?(customer.phone)
      return if CardBindingAttempt.growth_used_for_method_hash?(method_hash)

      mark_used!(
        phone: customer.phone,
        method_hash: method_hash,
        method_type: method_type,
        customer_id: customer.id,
        tenant_id: order.tenant_id
      )

      setting = PointCampaignSetting.card_binding_promo_for(order.tenant_id)
      setting&.refresh_counter!
    end

    # #76: промо только при enabled campaign и counter < threshold (агрегат по point_id).
    def self.point_allows_promo?(tenant)
      return false if tenant.blank?

      setting = PointCampaignSetting.card_binding_promo_for(tenant.id)
      return false unless setting&.enabled?

      count = CardBindingAttempt.growth_count_for_point(tenant.id)
      setting.update_column(:counter, count) if setting.counter != count
      count < setting.threshold.to_i
    end
    private_class_method :point_allows_promo?
  end
end
