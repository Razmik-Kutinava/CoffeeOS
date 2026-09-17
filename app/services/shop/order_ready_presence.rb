# frozen_string_literal: true

module Shop
  # #39 — presence гостя по WS: Rails.cache ключ order:{id}:online (Solid Cache / memory).
  # #82 Патч_1 — SMS_GRACE: suppress mark_online! (Cable reconnect ≠ SMS skipped).
  class OrderReadyPresence
    TTL = 15.minutes

    def self.cache_key(order_id)
      "order:#{order_id}:online"
    end

    def self.grace_key(order_id)
      "order:#{order_id}:sms_grace"
    end

    def self.begin_sms_grace!(order_id, duration: Shop::OrderReadyCascadeJob::SMS_GRACE)
      Rails.cache.write(grace_key(order_id), true, expires_in: duration)
      mark_offline!(order_id)
    end

    def self.in_sms_grace?(order_id)
      Rails.cache.read(grace_key(order_id)) == true
    end

    def self.mark_online!(order_id)
      return false if in_sms_grace?(order_id)

      Rails.cache.write(cache_key(order_id), true, expires_in: TTL)
      true
    end

    def self.mark_offline!(order_id)
      Rails.cache.delete(cache_key(order_id))
    end

    def self.online?(order_id)
      Rails.cache.read(cache_key(order_id)) == true
    end
  end
end
