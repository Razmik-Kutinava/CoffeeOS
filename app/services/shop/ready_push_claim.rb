# frozen_string_literal: true

module Shop
  # #35 C1/C2 — атомарный claim первого ready-push (UPDATE … WHERE ready_notified_at IS NULL).
  class ReadyPushClaim
    def self.claim!(order)
      now = Time.current

      # Atomically claim "first ready push" so concurrent enqueues don't double-send.
      # RLS: выполняем SET LOCAL app.current_tenant_id внутри транзакции, чтобы UPDATE ... при RLS был scoped.
      Order.transaction do
        conn = Order.connection
        begin
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(order.tenant_id.to_s)}")
        rescue ActiveRecord::StatementInvalid => e
          # Dev/test может быть без кастомных GUC/RLS bootstrap — не ломаем тесты.
          raise unless e.message.include?("unrecognized configuration parameter")
        end

        updated = Order.where(id: order.id, ready_notified_at: nil)
          .update_all(ready_notified_at: now, updated_at: now)

        order.reload if updated == 1
        updated == 1
      end
    end
  end
end
