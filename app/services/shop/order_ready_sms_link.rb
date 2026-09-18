# frozen_string_literal: true

require "base64"
require "openssl"

module Shop
  # TASK_93-C / #82 — короткий HMAC token для SMS `{host}/o/{hash}` (≤70 с префиксом).
  # 16 байт UUID + 4 байта HMAC-SHA256 → 27 символов urlsafe Base64 (не обратимый UUID).
  class OrderReadySmsLink
    DEFAULT_HOST = "coffeeos.fly.dev"
    TTL = 48.hours
    UUID_BYTES = 16
    MAC_BYTES = 4
    TOKEN_BYTES = UUID_BYTES + MAC_BYTES

    def self.link_host
      ENV["SHOP_SMS_LINK_HOST"].presence || ENV["APP_HOST"].presence || DEFAULT_HOST
    end

    def self.message_prefix
      # ≤70 с DEFAULT_HOST + 27-char hash: короче, чем «Заказ готов!»
      "CODE:BLACK. Готов! #{link_host}/o/"
    end

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

      order = Order.find_by(id: uuid, source: :mobile)
      return nil unless order
      return nil if link_expired?(order)

      order
    rescue ArgumentError, TypeError
      nil
    end

    def self.sms_message_for(order)
      "#{message_prefix}#{hash_for(order)}"
    end

    def self.link_expired?(order)
      anchor = order.ready_notified_at || order.ready_at || order.updated_at
      return true if anchor.blank?

      anchor < TTL.ago
    end
    private_class_method :link_expired?

    def self.secret
      Rails.application.key_generator.generate_key("shop/order_ready_sms_link", 32)
    end
    private_class_method :secret
  end
end
