# frozen_string_literal: true

module Platform
  class FranchiseOwnersController < BaseController
    def new
      @user = User.new(organization_id: params[:organization_id])
    end

    def create
      org = Organization.find_by(id: params.dig(:user, :organization_id))
      unless org
        @user = User.new(user_params)
        @user.errors.add(:base, "Организация не найдена")
        return render :new, status: :unprocessable_entity
      end

      anchor = org.tenants.order(:created_at).first
      unless anchor
        @user = User.new(user_params)
        @user.errors.add(:base, "Сначала создайте хотя бы одну точку для организации")
        return render :new, status: :unprocessable_entity
      end

      @user = User.new(user_params.merge(tenant_id: anchor.id, status: "active"))
      role = Role.find_or_create_by!(code: "franchise_manager") { |r| r.name = "Franchise manager" }

      if @user.save
        UserRole.find_or_create_by!(user: @user, role: role, tenant: anchor)
        redirect_to platform_root_path, notice: "Владелец (franchise_manager) создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :phone, :password, :organization_id)
    end
  end
end
