# frozen_string_literal: true

module Manager
  # Смена активной точки (франчайзи, УК) без полного стека Manager::BaseController.
  class TenantContextController < ApplicationController
    before_action :require_login

    def update
      tenant = Tenant.find_by(id: params.require(:tenant_id))
      unless tenant
        redirect_to manager_dashboard_path, alert: "Точка не найдена"
        return
      end

      unless current_user.franchise_manager? || current_user.uk_global_admin?
        redirect_to manager_dashboard_path, alert: "Недоступно"
        return
      end

      if current_user.franchise_manager? && tenant.organization_id != current_user.organization_id
        redirect_to manager_dashboard_path, alert: "Нет доступа к точке"
        return
      end

      session[:manager_tenant_id] = tenant.id.to_s
      redirect_to manager_dashboard_path, notice: "Точка: #{tenant.name}"
    end

    private

    def require_login
      return if session[:user_id]

      redirect_to login_path, alert: "Необходима авторизация"
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end
  end
end
