module PrepKitchen
  class BaseController < ApplicationController
    layout "prep_kitchen"
    helper_method :current_user

    before_action :require_login
    before_action :require_prep_kitchen_role
    before_action :set_tenant_context
    # Доступ ограничен require_prep_kitchen_role; fine-grained authorize при необходимости в подклассах.
    before_action :skip_authorization

    private

    def require_login
      return if session[:user_id].present?

      redirect_to login_path, alert: "Необходима авторизация"
    end

    def require_prep_kitchen_role
      return if current_user&.has_any_role?("prep_kitchen_manager", "prep_kitchen_worker")

      redirect_to root_path, alert: "Доступ запрещён"
    end

    def set_tenant_context
      Current.tenant_id = current_user.tenant_id
      Current.user_id = current_user.id
      Current.role_code = prep_kitchen_role_code

      return if Current.tenant_id.blank?

      set_pg_context(tenant_id: Current.tenant_id, user_id: Current.user_id)
    end

    def prep_kitchen_role_code
      role_from_session = session[:role_code]
      return role_from_session if current_user&.has_role?(role_from_session)

      return "prep_kitchen_manager" if current_user&.has_role?("prep_kitchen_manager")

      "prep_kitchen_worker"
    end

    def prep_kitchen_manager?
      Current.role_code == "prep_kitchen_manager"
    end

  end
end
