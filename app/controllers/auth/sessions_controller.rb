class Auth::SessionsController < ApplicationController
  include AuthLoginRls

  layout "auth"

  def new
    @user = User.new
  end

  def create
    email_or_phone = (params[:user]&.dig(:email) || params[:email] || "").strip.downcase
    password = params[:user]&.dig(:password) || params[:password] || ""

    user = nil
    with_auth_login_rls! do
      user = User.find_by("LOWER(email) = ? OR phone = ?", email_or_phone, email_or_phone)
    end

    if user && user.authenticate(password)
      unless user.active?
        flash.now[:alert] = "Аккаунт заблокирован"
        @user = User.new(email: email_or_phone)
        return render :new, status: :unprocessable_entity
      end

      Current.tenant_id = user.tenant_id
      Current.user_id = user.id

      user_roles = []
      with_auth_login_rls! { user_roles = user.roles.to_a }

      if user_roles.empty?
        flash.now[:alert] = "У вас нет назначенных ролей"
        @user = User.new(email: email_or_phone)
        return render :new, status: :unprocessable_entity
      end

      role = pick_login_role(user_roles)
      Current.role_code = role.code
      apply_session_after_login!(user, role.code)
      Auth::LoginJournal.record_login!(user: user, role_code: role.code, request: request)
      redirect_to dashboard_path_for_role(role.code), notice: "Добро пожаловать!"
    else
      flash.now[:alert] = "Неверный email/телефон или пароль"
      @user = User.new(email: email_or_phone)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    user = current_user
    role_code = session[:role_code]
    Auth::LoginJournal.record_logout!(user: user, role_code: role_code, request: request) if user
    session[:user_id] = nil
    session[:tenant_id] = nil
    session[:role_code] = nil
    session[:logged_in_at] = nil
    session[:manager_tenant_id] = nil
    Current.tenant_id = nil
    Current.user_id = nil
    Current.role_code = nil
    redirect_to login_path, notice: "Вы вышли из системы"
  end

  private

  # При нескольких ролях — приоритетная (franchise_manager выше barista и т.д.).
  LOGIN_ROLE_PRIORITY = %w[
    ук_global_admin ук_country_manager ук_billing_admin
    franchise_manager general_manager shift_manager
    barista prep_kitchen_manager prep_kitchen_worker blog_editor
  ].freeze

  def pick_login_role(user_roles)
    user_roles.min_by do |role|
      idx = LOGIN_ROLE_PRIORITY.index(role.code)
      idx.nil? ? LOGIN_ROLE_PRIORITY.length : idx
    end
  end

  def apply_session_after_login!(user, role_code)
    session[:user_id] = user.id
    session[:tenant_id] = user.tenant_id
    session[:role_code] = role_code
    session[:logged_in_at] = Time.current.iso8601

    if user.uk_global_admin?
      session[:manager_tenant_id] = nil
    elsif user.franchise_manager? && user.organization_id.present?
      first = user.accessible_manager_tenants.first
      session[:manager_tenant_id] = first&.id&.to_s
    else
      session[:manager_tenant_id] = nil
    end
  end

  def dashboard_path_for_role(role_code)
    case role_code
    when "blog_editor"
      blog_root_path
    when "barista"
      barista_dashboard_path
    when "shift_manager", "general_manager"
      manager_dashboard_path
    when "franchise_manager"
      manager_dashboard_path
    when "prep_kitchen_worker", "prep_kitchen_manager"
      prep_kitchen_dashboard_path
    when "ук_global_admin", "ук_country_manager", "ук_billing_admin"
      platform_root_path
    else
      root_path
    end
  end
end
