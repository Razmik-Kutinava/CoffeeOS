module Barista
  class BaseController < ApplicationController
    layout 'barista'
    before_action :require_login
    before_action :require_barista_role
    before_action :set_tenant_context
    
    private
    
    def require_login
      unless session[:user_id]
        redirect_to login_path, alert: "Необходима авторизация"
        return
      end
    end
    
    def require_barista_role
      user = current_user
      # BUG-013 FIX: Проверяем что пользователь не заблокирован при каждом запросе.
      unless user&.active?
        reset_session
        redirect_to login_path, alert: "Ваша учётная запись заблокирована"
        return
      end
      unless user.has_role?('barista')
        redirect_to root_path, alert: "Доступ запрещён"
        return
      end
    end
    
    def set_tenant_context
      Current.tenant_id = current_user.tenant_id
      Current.user_id   = current_user.id
      Current.role_code = 'barista'

      return unless Current.tenant_id

      set_pg_context(tenant_id: Current.tenant_id, user_id: Current.user_id)
    end


    def current_shift
      @current_shift ||= CashShift.lock.find_by(tenant_id: Current.tenant_id, status: 'open')
    end
  end
end
