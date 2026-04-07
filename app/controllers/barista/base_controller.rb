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
      unless user&.has_role?('barista')
        redirect_to root_path, alert: "Доступ запрещён"
        return
      end
    end
    
    def set_tenant_context
      Current.tenant_id = current_user.tenant_id
      Current.user_id = current_user.id
      Current.role_code = 'barista'
      
      # Устанавливаем PostgreSQL контекст для RLS
      return unless Current.tenant_id
      
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(Current.tenant_id.to_s)}")
      conn.execute("SET LOCAL app.current_user_id = #{conn.quote(Current.user_id.to_s)}") if Current.user_id
    end
    
    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end
    
    def current_shift
      @current_shift ||= CashShift.find_by(tenant_id: Current.tenant_id, status: 'open')
    end
  end
end
