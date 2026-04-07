# frozen_string_literal: true

module Platform
  class BaseController < ApplicationController
    layout "platform"

    before_action :require_login
    before_action :require_uk_global_admin
    before_action :assign_current_for_rls

    private

    # RLS на product_tenant_settings и др. читает app.current_user_id / app.current_tenant_id в PostgreSQL.
    # Без Current.user_id контекст в callbacks ApplicationRecord может не совпасть с политикой.
    def assign_current_for_rls
      return unless current_user

      Current.user_id = current_user.id
    end

    def require_login
      return if session[:user_id]

      redirect_to login_path, alert: "Необходима авторизация"
    end

    def require_uk_global_admin
      return if current_user&.uk_global_admin?

      redirect_to root_path, alert: "Доступ только для УК"
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end
  end
end
