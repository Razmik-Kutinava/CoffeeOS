# frozen_string_literal: true

module Shop
  # #35 C1/C2 — атомарный claim первого ready-push (UPDATE … WHERE ready_notified_at IS NULL).
  class ReadyPushClaim
    def self.claim!(order)
      now = Time.current
      # RLS: обновление по PK заказа; tenant isolation уже в контексте вызова (broadcaster/POS).
      updated = Order.where(id: order.id, ready_notified_at: nil)
        .update_all(ready_notified_at: now, updated_at: now)

      order.reload if updated == 1
      updated == 1
    end
  end
end
