# frozen_string_literal: true

module Auth
  # Запись активной сессии в таблицу sessions (§2A.3 — «кто онлайн на точке»).
  class SessionTracker
    EXPIRY = 24.hours

    class << self
      def start!(user:, rack_session:, request:, context_tenant_id:)
        db_session = Session.create!(
          user: user,
          tenant_id: context_tenant_id,
          token: SecureRandom.urlsafe_base64(32),
          expires_at: EXPIRY.from_now,
          ip_address: request.remote_ip,
          user_agent: request.user_agent&.truncate(500)
        )
        rack_session[:db_session_id] = db_session.id
        db_session
      end

      def end!(rack_session:)
        id = rack_session[:db_session_id]
        Session.find_by(id: id)&.revoke! if id.present?
        rack_session[:db_session_id] = nil
      end
    end
  end
end
