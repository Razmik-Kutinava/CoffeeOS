# frozen_string_literal: true

require "base64"
require "openssl"

module Shop
  # #82 Патч_1 — короткий HMAC token для SMS `codeblack.xyz/o/{hash}` (≤70 с префиксом).
  # 16 байт UUID + 4 байта HMAC-SHA256 → 27 символов urlsafe Base64 (не обратимый UUID).
  class OrderReadySmsLink
    PREFIX = "CODE:BLACK. Заказ готов! codeblack.xyz/o/"
    UUID_BYTES = 16
    MAC_BYTES = 4
    TOKEN_BYTES = UUID_BYTES + MAC_BYTES

    def self.hash_for(order)
      uuid_hex = order.id.to_s.delete("-")
      uuid_bytes = [ uuid_hex ].pack("H*")
      mac = OpenSSL::HMAC.digest("SHA256", secret, order.id.to_s)[0, MAC_BYTES]
      Base64.urlsafe_encode64(uuid_bytes + mac, padding: false)
    end

    def self.find_order(order_hash)
      raw = Base64.urlsafe_decode64(order_hash.to_s)
      return nil unless raw&.bytesize == TOKEN_BYTES

      uuid_bytes = raw.byteslice(0, UUID_BYTES)
      mac = raw.byteslice(UUID_BYTES, MAC_BYTES)
      hex = uuid_bytes.unpack1("H*")
      return nil unless hex&.length == 32

      uuid = [
        hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]
      ].join("-")
      expected = OpenSSL::HMAC.digest("SHA256", secret, uuid)[0, MAC_BYTES]
      return nil unless ActiveSupport::SecurityUtils.secure_compare(mac, expected)

      Order.find_by(id: uuid, source: :mobile)
    rescue ArgumentError, TypeError
      nil
    end

    def self.sms_message_for(order)
      "#{PREFIX}#{hash_for(order)}"
    end

    def self.secret
      Rails.application.key_generator.generate_key("shop/order_ready_sms_link", 32)
    end
    private_class_method :secret
  end
end
