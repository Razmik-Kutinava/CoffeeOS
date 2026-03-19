module Manager
  class BaseController < ApplicationController
    layout "manager"

    before_action :require_login
    before_action :require_manager_role
    before_action :set_tenant_context

    private

    def require_login
      return if session[:user_id]

      redirect_to login_path, alert: "Необходима авторизация"
    end

    def require_manager_role
      user = current_user
      return if user&.has_any_role?("office_manager", "shift_manager")

      redirect_to root_path, alert: "Доступ запрещён"
    end

    def set_tenant_context
      Current.tenant_id = current_user.tenant_id
      Current.user_id = current_user.id

      # Панель manager может работать в разных режимах:
      # - office_manager: "вся точка"
      # - shift_manager: "текущая открытая смена"
      Current.role_code = manager_role_code

      return unless Current.tenant_id

      # Устанавливаем PostgreSQL контекст для RLS (как в Barista)
      ActiveRecord::Base.connection.execute(
        "SET LOCAL app.current_tenant_id = '#{Current.tenant_id}'"
      )
      ActiveRecord::Base.connection.execute(
        "SET LOCAL app.current_user_id = '#{Current.user_id}'"
      ) if Current.user_id
    end

    def manager_role_code
      # На входе `Auth::SessionsController` кладёт session[:role_code],
      # но `Manager::BaseController` ранее перезатирал его фиксированным office_manager.
      role_from_session = session[:role_code]
      return role_from_session if current_user&.has_role?(role_from_session)

      return "shift_manager" if current_user&.has_role?("shift_manager")
      "office_manager"
    end

    def shift_manager?
      Current.role_code == "shift_manager"
    end

    def office_manager?
      Current.role_code == "office_manager"
    end

    def current_cash_shift
      # Для shift_manager "текущая смена" = открытая cash_shift этой точки (в проекте на tenant максимум одна open).
      @current_cash_shift ||= CashShift.for_current_tenant.open.order(opened_at: :desc).first
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def current_tenant
      @current_tenant ||= current_user&.tenant
    end
  end
end

