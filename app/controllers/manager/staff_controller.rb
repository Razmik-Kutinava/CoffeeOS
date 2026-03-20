# frozen_string_literal: true

module Manager
  class StaffController < BaseController
    helper_method :assignable_staff_role_codes

    before_action :require_privileged_manager!
    before_action :set_staff_user, only: %i[edit update]

    def index
      tid = Current.tenant_id
      uids = UserRole.where(tenant_id: tid).distinct.pluck(:user_id)
      @users = User.where(tenant_id: tid).or(User.where(id: uids)).distinct.includes(:roles).order(:name).limit(500)
      @roles = Role.order(:code)
    end

    def new
      @user = User.new(tenant_id: Current.tenant_id)
    end

    def create
      @user = User.new(staff_user_params.merge(tenant_id: Current.tenant_id, status: "active"))
      if @user.save
        sync_roles!(@user, role_codes_param)
        redirect_to manager_staff_members_path, notice: "Сотрудник создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      p = staff_user_params
      p = p.except(:password) if p[:password].blank?
      if @user.update(p)
        sync_roles!(@user, role_codes_param)
        redirect_to manager_staff_members_path, notice: "Сохранено"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_staff_user
      tid = Current.tenant_id
      uids = UserRole.where(tenant_id: tid).pluck(:user_id)
      @user = User.where(tenant_id: tid).or(User.where(id: uids)).find(params[:id])
    end

    def staff_user_params
      params.require(:user).permit(:name, :email, :phone, :password)
    end

    def role_codes_param
      Array(params[:role_codes]).map(&:to_s).reject(&:blank?)
    end

    def sync_roles!(user, codes)
      tenant = Tenant.find(Current.tenant_id)
      codes = (codes & assignable_role_codes).map(&:to_s)

      if office_manager? && !franchise_manager? && !current_user.uk_global_admin?
        codes -= ["office_manager"]
      end

      desired_ids = codes.filter_map do |c|
        next if %w[franchise_manager ук_global_admin].include?(c)

        Role.find_or_create_by!(code: c) { |r| r.name = c.humanize }.id
      end

      UserRole.where(user_id: user.id, tenant_id: tenant.id).where.not(role_id: desired_ids).delete_all

      desired_ids.each do |rid|
        UserRole.find_or_create_by!(user_id: user.id, role_id: rid, tenant_id: tenant.id)
      end
    end

    def assignable_role_codes
      %w[barista shift_manager office_manager prep_kitchen_worker prep_kitchen_manager]
    end

    def assignable_staff_role_codes
      c = assignable_role_codes.dup
      if office_manager? && !franchise_manager? && !current_user.uk_global_admin?
        c -= ["office_manager"]
      end
      c
    end
  end
end
