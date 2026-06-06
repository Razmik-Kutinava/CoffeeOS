# frozen_string_literal: true

module Platform
  # Сводка пользователей, активных сессий и входов по точке для УК (§2A.3).
  class TenantSessionsOverview
    LOGIN_META_WINDOW = 7.days

    def initialize(tenant)
      @tenant = tenant
    end

    def call
      users = load_users
      active_sessions = load_active_sessions
      active_by_user = active_sessions.group_by(&:user_id)
      login_meta = build_login_meta
      logout_meta = build_logout_meta

      {
        tenant: { id: @tenant.id, name: @tenant.name, slug: @tenant.slug },
        users_count: users.size,
        active_sessions_count: active_sessions.size,
        online_count: active_by_user.keys.size,
        roles_summary: roles_summary(users),
        users: users.map { |user| user_row(user, active_by_user[user.id] || [], login_meta, logout_meta) },
        active_sessions: active_sessions.map { |s| session_row(s, login_meta[s.user_id]) },
        recent_events: load_session_events
      }
    end

    private

    def load_user_ids
      role_ids = UserRole.where(tenant_id: @tenant.id).distinct.pluck(:user_id)
      direct_ids = User.where(tenant_id: @tenant.id).pluck(:id)
      (role_ids + direct_ids).uniq
    end

    def load_users
      ids = load_user_ids
      return [] if ids.empty?

      User.where(id: ids).includes(user_roles: :role).order(:name).to_a
    end

    def tenant_role_codes(user)
      user.user_roles.select { |ur| ur.tenant_id == @tenant.id }.map { |ur| ur.role.code }
    end

    def load_active_sessions
      Session.active.where(tenant_id: @tenant.id).includes(:user).order(created_at: :desc).to_a
    end

    def build_login_meta
      meta = {}
      AdminAuditLog.for_tenant(@tenant.id)
        .where(action: Auth::LoginJournal::ACTION_LOGIN)
        .where("created_at >= ?", LOGIN_META_WINDOW.ago)
        .order(created_at: :desc)
        .limit(500)
        .each do |log|
          uid = log.details["user_id"]
          next if uid.blank? || meta.key?(uid)

          meta[uid] = {
            at: log.created_at.iso8601,
            role_code: log.details["role_code"],
            ip: log.details["ip"]
          }
        end
      meta
    end

    def build_logout_meta
      meta = {}
      AdminAuditLog.for_tenant(@tenant.id)
        .where(action: Auth::LoginJournal::ACTION_LOGOUT)
        .where("created_at >= ?", LOGIN_META_WINDOW.ago)
        .order(created_at: :desc)
        .limit(500)
        .each do |log|
          uid = log.details["user_id"]
          next if uid.blank? || meta.key?(uid)

          meta[uid] = { at: log.created_at.iso8601 }
        end
      meta
    end

    def roles_summary(users)
      users.each_with_object(Hash.new(0)) do |user, acc|
        tenant_role_codes(user).each { |code| acc[code] += 1 }
      end.sort.to_h
    end

    def user_row(user, active_sessions, login_meta, logout_meta)
      login = login_meta[user.id]
      logout = logout_meta[user.id]
      {
        user_id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        status: user.status,
        roles: tenant_role_codes(user),
        online: active_sessions.any?,
        active_sessions_count: active_sessions.size,
        last_login_at: login&.dig(:at),
        last_login_role: login&.dig(:role_code),
        last_logout_at: logout&.dig(:at),
        active_sessions: active_sessions.map { |s| session_row(s, login) }
      }
    end

    def session_row(session, login_meta = nil)
      {
        session_id: session.id,
        user_id: session.user_id,
        email: session.user.email,
        name: session.user.name,
        role_code: login_meta&.dig(:role_code),
        tenant_id: session.tenant_id,
        ip_address: session.ip_address,
        user_agent: session.user_agent,
        logged_in_at: session.created_at.iso8601,
        expires_at: session.expires_at.iso8601
      }
    end

    def load_session_events
      feed = Health::TenantEventFeed.new(@tenant).call
      feed[:unified_feed].select { |e| e[:check].to_s == "session" }
    end
  end
end
