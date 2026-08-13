# frozen_string_literal: true

module Payments
  # [TDD] Шаг 1 ТЗ: inline-инициализация для Т-Банка
  # - если есть RebillId: делаем Init → Charge (для Charge нужен PaymentId)
  # - иначе: делаем Init с PayType: "O" (двухстадийная оплата)
  class TbankInlineInit
    def self.call(order:, return_base_url:, notification_url:, rebill_id: nil, customer_key: nil, connection_type: nil, adapter: Payments::TbankAdapter.new)
      data = connection_type.present? ? { "connection_type" => connection_type.to_s } : nil

      if rebill_id.to_s.present?
        init_result = adapter.init_payment(
          order: order,
          return_base_url: return_base_url,
          notification_url: notification_url,
          customer_key: customer_key,
          recurrent: false,
          data: data
        )

        charge_response = adapter.charge(
          payment_id: init_result[:provider_payment_id],
          rebill_id: rebill_id
        )

        { provider_payment_id: charge_response["PaymentId"].to_s }
      else
        init_result = adapter.init_payment(
          order: order,
          return_base_url: return_base_url,
          notification_url: notification_url,
          customer_key: customer_key,
          recurrent: false,
          pay_type: "O",
          data: data
        )

        { provider_payment_id: init_result[:provider_payment_id] }
      end
    end
  end
end
