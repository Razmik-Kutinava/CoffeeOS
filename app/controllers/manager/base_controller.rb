module Manager
  class BaseController < ApplicationController
    layout "manager"

    before_action :require_login
    before_action :require_manager_role
    before_action :ensure_franchise_tenant_session!
    before_action :ensure_uk_manager_tenant!
    before_action :set_tenant_context
    # Роль-доступ обеспечивается require_manager_role выше.
    # Конкретные CRUD-действия могут переопределить через authorize @resource.
    before_action :skip_authorization

    helper_method :franchise_manager?, :office_manager?, :office_or_franchise_manager?, :shift_manager?,
                  :accessible_manager_tenants, :current_tenant, :uk_in_manager?

    def uk_in_manager?
      current_user&.uk_global_admin?
    end

    def require_privileged_manager!
      return if office_or_franchise_manager? || current_user.uk_global_admin?

      redirect_to manager_dashboard_path, alert: "Доступ запрещён"
    end

    private

    def require_login
      return if session[:user_id]

      redirect_to login_path, alert: "Необходима авторизация"
    end

    def require_manager_role
      user = current_user
      # BUG-013 FIX: Проверяем что пользователь не заблокирован при каждом запросе.
      unless user&.active?
        reset_session
        redirect_to login_path, alert: "Ваша учётная запись заблокирована"
        return
      end
      return if user.has_any_role?("office_manager", "shift_manager", "franchise_manager") || user.uk_global_admin?

      redirect_to root_path, alert: "Доступ запрещён"
    end

    # Франчайзи: выбранная точка в сессии; список точек организации.
    def ensure_franchise_tenant_session!
      return unless current_user&.franchise_manager?

      unless current_user.organization_id
        redirect_to root_path, alert: "Нет организации"
        return
      end

      list = Tenant.where(organization_id: current_user.organization_id).order(:name).to_a
      if list.empty?
        redirect_to root_path, alert: "У организации нет точек"
        return
      end

      tid = session[:manager_tenant_id].to_s
      if tid.blank? || list.none? { |t| t.id.to_s == tid }
        session[:manager_tenant_id] = list.first.id.to_s
      end
    end

    # УК в manager только с выбранной точкой (из админки).
    def ensure_uk_manager_tenant!
      return unless current_user&.uk_global_admin?
      return if session[:manager_tenant_id].present?

      redirect_to platform_root_path, alert: "Выберите точку в админке УК"
    end

    def set_tenant_context
      Current.user_id = current_user.id

      Current.tenant_id =
        if current_user.uk_global_admin?
          session[:manager_tenant_id]
        elsif current_user.franchise_manager?
          session[:manager_tenant_id]
        else
          current_user.tenant_id
        end

      Current.role_code = manager_role_code

      return if Current.tenant_id.blank?

      set_pg_context(tenant_id: Current.tenant_id, user_id: Current.user_id)
    end

    def manager_role_code
      return "office_manager" if current_user&.uk_global_admin?

      role_from_session = session[:role_code]
      return role_from_session if current_user&.has_role?(role_from_session)

      return "shift_manager" if current_user&.has_role?("shift_manager")
      return "franchise_manager" if current_user&.franchise_manager?
      return "office_manager" if current_user&.has_role?("office_manager")
      "office_manager"
    end

    def shift_manager?
      Current.role_code == "shift_manager"
    end

    def office_manager?
      Current.role_code == "office_manager"
    end

    def franchise_manager?
      Current.role_code == "franchise_manager"
    end

    def office_or_franchise_manager?
      office_manager? || franchise_manager?
    end

    def accessible_manager_tenants
      return Tenant.none unless current_user&.franchise_manager? && current_user.organization_id

      Tenant.where(organization_id: current_user.organization_id).order(:name)
    end

    def current_cash_shift
      @current_cash_shift ||= CashShift.for_current_tenant.open.order(opened_at: :desc).first
    end

    def current_tenant
      @current_tenant ||= Tenant.find_by(id: Current.tenant_id) if Current.tenant_id
    end

    def require_office_or_franchise_manager!
      return if office_or_franchise_manager?

      redirect_to manager_dashboard_path, alert: "Доступ запрещён"
    end
  end
end
