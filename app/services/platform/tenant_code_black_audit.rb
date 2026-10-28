# frozen_string_literal: true

module Platform
  # TASK_115: изменение членства точки в сети CODE:BLACK → admin_audit_logs (кто, когда, было, стало).
  # Вызывать внутри транзакции сохранения точки: откат формы откатывает и запись журнала.
  class TenantCodeBlackAudit
    ACTION = "tenant_code_black_member_changed"

    def self.call(tenant:, actor:, was:, request_id: nil)
      now = tenant.code_black_member
      return if was == now

      AdminAuditLog.log(
        action: ACTION,
        actor: actor,
        entity: tenant,
        tenant_id: tenant.id,
        details: { field: "code_black_member", from: was, to: now },
        request_id: request_id
      )
    end
  end
end
