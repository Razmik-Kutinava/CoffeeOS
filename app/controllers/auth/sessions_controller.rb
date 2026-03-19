class Auth::SessionsController < ApplicationController
  # Пока нет Devise, убираем authenticate_user!
  # skip_before_action :authenticate_user!, only: [:new, :create]
  
  layout 'auth'
  
  def new
    @user = User.new
  end
  
  def create
    email_or_phone = (params[:user]&.dig(:email) || params[:email] || "").strip.downcase
    password = params[:user]&.dig(:password) || params[:password] || ""
    
    # Поиск пользователя по email или phone
    user = User.find_by("LOWER(email) = ? OR phone = ?", email_or_phone, email_or_phone)
    
    if user && user.authenticate(password)
      # Проверка статуса пользователя
      unless user.active?
        flash.now[:alert] = "Аккаунт заблокирован"
        @user = User.new(email: email_or_phone)
        return render :new, status: :unprocessable_entity
      end
      
      # Установка контекста
      Current.tenant_id = user.tenant_id
      Current.user_id = user.id
      
      # Проверка количества ролей
      user_roles = user.roles.to_a
      
      if user_roles.empty?
        flash.now[:alert] = "У вас нет назначенных ролей"
        @user = User.new(email: email_or_phone)
        return render :new, status: :unprocessable_entity
      elsif user_roles.size == 1
        # Одна роль - сразу редирект
        Current.role_code = user_roles.first.code
        # Временная сессия без Devise
        session[:user_id] = user.id
        session[:tenant_id] = user.tenant_id
        session[:role_code] = user_roles.first.code
        redirect_to dashboard_path_for_role(user_roles.first.code), notice: "Добро пожаловать!"
      else
        # Несколько ролей - пока редирект на первую (позже добавим выбор)
        Current.role_code = user_roles.first.code
        session[:user_id] = user.id
        session[:tenant_id] = user.tenant_id
        session[:role_code] = user_roles.first.code
        redirect_to dashboard_path_for_role(user_roles.first.code), notice: "Добро пожаловать!"
      end
    else
      flash.now[:alert] = "Неверный email/телефон или пароль"
      @user = User.new(email: email_or_phone)
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    # Временный logout без Devise
    session[:user_id] = nil
    session[:tenant_id] = nil
    session[:role_code] = nil
    Current.tenant_id = nil
    Current.user_id = nil
    Current.role_code = nil
    redirect_to login_path, notice: "Вы вышли из системы"
  end
  
  private
  
  def dashboard_path_for_role(role_code)
    case role_code
    when 'barista'
      barista_dashboard_path
    when 'shift_manager', 'office_manager'
      manager_dashboard_path
    when 'prep_kitchen_worker', 'prep_kitchen_manager'
      prep_kitchen_dashboard_path
    when 'franchise_manager', 'ук_global_admin', 'ук_country_manager', 'ук_billing_admin'
      admin_dashboard_path
    else
      root_path
    end
  end
end
