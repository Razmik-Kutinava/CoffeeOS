# frozen_string_literal: true

module Auth
  # Журнал входов/выходов → AdminAuditLog для трассировки «кто залогинен» (§2A.3).
  class LoginJournal
    ACTION_LOGIN = "user_login"
    ACTION_LOGOUT = "user_logout"

    class << self
      def record_login!(user:, role_code:, request: nil, context_tenant_id: nil)
        new(user: user, action: ACTION_LOGIN, role_code: role_code, request: request, context_tenant_id: context_tenant_id).call!
      end

      def record_logout!(user:, role_code: nil, request: nil, context_tenant_id: nil)
        new(user: user, action: ACTION_LOGOUT, role_code: role_code, request: request, context_tenant_id: context_tenant_id).call!
      end
    end

    def initialize(user:, action:, role_code: nil, request: nil, context_tenant_id: nil)
      @user = user
      @action = action
      @role_code = role_code
      @request = request
      @context_tenant_id = context_tenant_id
    end

    def call!
      AdminAuditLog.log(
        action: @action,
        actor: @user,
        entity: @user,
        tenant_id: @context_tenant_id || @user.tenant_id,
        details: {
          user_id: @user.id,
          email: @user.email,
          name: @user.name,
          role_code: @role_code,
          ip: @request&.remote_ip,
          user_agent: @request&.user_agent&.truncate(200)
        },
        request_id: @request&.request_id
      )
    end
  end
end
