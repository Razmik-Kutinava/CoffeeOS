class DashboardsController < ApplicationController
  layout 'application'
  before_action :require_login
  
  def barista
    @user = current_user
    @role = 'Бариста'
  end
  
  def manager
    @user = current_user
    @role = 'Менеджер'
  end
  
  def prep_kitchen
    @user = current_user
    @role = 'Кухня'
  end
  
  def admin
    @user = current_user
    @role = 'Админ'
  end
  
  private
  
  def require_login
    unless session[:user_id]
      redirect_to login_path, alert: "Необходима авторизация"
    end
  end
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
