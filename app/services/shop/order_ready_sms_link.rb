# frozen_string_literal: true

require "base64"

module Shop
  # #82 Патч_1 — короткий order_hash для SMS `codeblack.xyz/o/{hash}` (≤70 с префиксом).
  # UUID → 16 байт → urlsafe Base64 без padding (22 символа) → обратимый lookup.
  class OrderReadySmsLink
    PREFIX = "CODE:BLACK. Заказ готов! codeblack.xyz/o/"

    def self.hash_for(order)
      uuid_hex = order.id.to_s.delete("-")
      Base64.urlsafe_encode64([ uuid_hex ].pack("H*"), padding: false)
    end

    def self.find_order(order_hash)
      hex = Base64.urlsafe_decode64(order_hash.to_s).unpack1("H*")
      return nil unless hex&.length == 32

      uuid = [
        hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]
      ].join("-")
      Order.find_by(id: uuid, source: :mobile)
    rescue ArgumentError, TypeError
      nil
    end

    def self.sms_message_for(order)
      "#{PREFIX}#{hash_for(order)}"
    end
  end
end
