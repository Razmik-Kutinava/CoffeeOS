# frozen_string_literal: true

module Platform
  # Текущая сессия УК — для UI и JSON `/admin/session` (§2A.3).
  class SessionInfo
    def initialize(user, rack_session)
      @user = user
      @session = rack_session
    end

    def to_h
      {
        user_id: @user.id,
        email: @user.email,
        name: @user.name,
        role_code: @session[:role_code],
        tenant_id: @session[:tenant_id],
        manager_tenant_id: @session[:manager_tenant_id],
        logged_in_at: @session[:logged_in_at],
        generated_at: Time.current.iso8601
      }
    end
  end
end
