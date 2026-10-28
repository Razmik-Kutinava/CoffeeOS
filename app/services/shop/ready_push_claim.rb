# frozen_string_literal: true

module Shop
  # #35 C1/C2 — атомарный claim первого ready-push (UPDATE … WHERE ready_notified_at IS NULL).
  # TASK_92 Патч 1 — release! перед повтором; повтор ставит claim с исходным временем
  # (`at:`), чтобы не сдвинуть начало срока SMS-ссылки (OrderReadySmsLink#link_expired?).
  class ReadyPushClaim
    def self.claim!(order, at: nil)
      now = Time.current

      # Atomically claim "first ready push" so concurrent enqueues don't double-send.
      with_tenant_transaction(order) do
        updated = Order.where(id: order.id, ready_notified_at: nil)
          .update_all(ready_notified_at: at || now, updated_at: now)

        order.reload if updated == 1
        updated == 1
      end
    end

    # Снимает только свой claim: чужой (другое время) не трогает.
    def self.release!(order, claimed_at)
      with_tenant_transaction(order) do
        Order.where(id: order.id, ready_notified_at: claimed_at)
          .update_all(ready_notified_at: nil) == 1
      end
    end

    # RLS: выполняем SET LOCAL app.current_tenant_id внутри транзакции, чтобы UPDATE ... при RLS был scoped.
    def self.with_tenant_transaction(order)
      Order.transaction do
        conn = Order.connection
        begin
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(order.tenant_id.to_s)}")
        rescue ActiveRecord::StatementInvalid => e
          # Dev/test может быть без кастомных GUC/RLS bootstrap — не ломаем тесты.
          raise unless e.message.include?("unrecognized configuration parameter")
        end

        yield
      end
    end
    private_class_method :with_tenant_transaction
  end
end
