# frozen_string_literal: true

module Payments
  # Собирает объект Receipt для Init Т-Кассы (54-ФЗ / ФФД).
  # Taxation и Tax позиции — из ENV (без хардкода секретов).
  #
  # Контакт (#72): приоритет Email над Phone; без контакта / невалидный email → Error до Init.
  #
  # ENV:
  #   TBANK_TAXATION — система налогообложения (osn, usn_income, …); default usn_income
  #   TBANK_TAX      — ставка НДС позиции (none, vat20, …); default none
  class TbankReceiptBuilder
    class Error < StandardError; end

    DEFAULT_TAXATION = "usn_income"
    DEFAULT_TAX = "none"
    NAME_MAX_LEN = 128
    EMAIL_FORMAT = /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/

    def self.call!(order:, email: nil, phone: nil)
      new(order: order, email: email, phone: phone).call!
    end

    # Контакт из MobileCustomer заказа (доверенные данные, не UI).
    def self.for_order!(order)
      customer = order.respond_to?(:customer) ? order.customer : nil
      call!(order: order, email: customer&.email, phone: customer&.phone)
    end

    def initialize(order:, email: nil, phone: nil)
      @order = order
      @email = email
      @phone = phone
    end

    def call!
      items = Array(@order.order_items)
      raise Error, "Нет позиций заказа для чека 54-ФЗ" if items.empty?

      receipt = {
        "Taxation" => taxation,
        "Items" => items.map { |item| build_item(item) }
      }
      apply_contact!(receipt)
      receipt
    end

    private

    def apply_contact!(receipt)
      email = @email.to_s.strip.presence
      phone = @phone.to_s.strip.presence

      if email
        raise Error, "Некорректный email для чека 54-ФЗ" unless valid_email?(email)

        receipt["Email"] = email
        return
      end

      if phone
        receipt["Phone"] = phone
        return
      end

      raise Error, "Нужен email или телефон покупателя для чека 54-ФЗ"
    end

    def valid_email?(email)
      email.match?(EMAIL_FORMAT)
    end

    def taxation
      ENV.fetch("TBANK_TAXATION", DEFAULT_TAXATION).to_s.presence || DEFAULT_TAXATION
    end

    def tax
      ENV.fetch("TBANK_TAX", DEFAULT_TAX).to_s.presence || DEFAULT_TAX
    end

    def build_item(item)
      qty = item.quantity.to_f
      price_kopecks = (BigDecimal(item.unit_price.to_s) * 100).to_i
      amount_kopecks = (BigDecimal(item.total_price.to_s) * 100).to_i

      {
        "Name" => truncate_name(item.product_name.to_s),
        "Price" => price_kopecks,
        "Quantity" => qty,
        "Amount" => amount_kopecks,
        "Tax" => tax,
        "PaymentMethod" => "full_payment",
        "PaymentObject" => "commodity"
      }
    end

    def truncate_name(name)
      return name if name.length <= NAME_MAX_LEN

      name[0, NAME_MAX_LEN]
    end
  end
end
