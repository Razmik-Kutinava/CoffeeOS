# frozen_string_literal: true

module Shop
  # #39 — presence гостя по WS: Rails.cache ключ order:{id}:online (Solid Cache / memory).
  class OrderReadyPresence
    TTL = 15.minutes

    def self.cache_key(order_id)
      "order:#{order_id}:online"
    end

    def self.mark_online!(order_id)
      Rails.cache.write(cache_key(order_id), true, expires_in: TTL)
    end

    def self.mark_offline!(order_id)
      Rails.cache.delete(cache_key(order_id))
    end

    def self.online?(order_id)
      Rails.cache.read(cache_key(order_id)) == true
    end
  end
end
