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
    before_action :assign_shift_for_layout

    helper_method :franchise_manager?, :general_manager?, :general_or_franchise_manager?, :shift_manager?,
                  :accessible_manager_tenants, :current_tenant, :uk_in_manager?, :current_cash_shift,
                  :staff_management_visible?, :inventory_management_visible?

    def staff_management_visible?
      general_manager? || uk_in_manager?
    end

    def inventory_management_visible?
      general_or_franchise_manager?
    end

    def require_staff_management!
      return if staff_management_visible?

      redirect_to manager_dashboard_path, alert: "Доступ запрещён"
    end

    def uk_in_manager?
      current_user&.uk_global_admin?
    end

    def require_privileged_manager!
      return if general_or_franchise_manager? || current_user.uk_global_admin?

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
      tid = Current.tenant_id || user.tenant_id
      return if user.has_any_role_in_context?(
        "general_manager", "shift_manager", "franchise_manager",
        tenant_id: tid, organization_id: user.organization_id
      ) || user.has_role_in_context?("ук_global_admin")

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
      user = current_user
      return "general_manager" if user&.has_role_in_context?("ук_global_admin")

      role_from_session = session[:role_code]
      tid = Current.tenant_id || user&.tenant_id
      return role_from_session if role_from_session.present? && user&.has_role_in_context?(
        role_from_session, tenant_id: tid, organization_id: user.organization_id
      )

      return "shift_manager" if user&.has_role_in_context?("shift_manager", tenant_id: tid)
      return "franchise_manager" if user&.franchise_manager?
      return "general_manager" if user&.has_role_in_context?("general_manager", tenant_id: tid)
      "general_manager"
    end

    def shift_manager?
      Current.role_code == "shift_manager"
    end

    def general_manager?
      Current.role_code == "general_manager"
    end

    def franchise_manager?
      Current.role_code == "franchise_manager"
    end

    def general_or_franchise_manager?
      general_manager? || franchise_manager?
    end

    def accessible_manager_tenants
      return Tenant.none unless current_user&.franchise_manager? && current_user.organization_id

      Tenant.where(organization_id: current_user.organization_id).order(:name)
    end

    def assign_shift_for_layout
      @open_cash_shift = current_cash_shift
    end

    def current_cash_shift
      return nil unless Current.tenant_id

      @current_cash_shift ||= CashShift.for_current_tenant.open.order(opened_at: :desc).first
    end

    def current_tenant
      @current_tenant ||= Tenant.find_by(id: Current.tenant_id) if Current.tenant_id
    end

    def require_general_or_franchise_manager!
      return if general_or_franchise_manager?

      redirect_to manager_dashboard_path, alert: "Доступ запрещён"
    end

    def pundit_user
      @pundit_user ||= PolicyContext.build(
        user: current_user,
        tenant_id: Current.tenant_id,
        role_code: Current.role_code,
        shift: current_cash_shift
      )
    end
  end
end
