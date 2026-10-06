# frozen_string_literal: true

module Platform
  # Владелец франшизы = franchise_manager на уровне организации (UserRole.tenant_id NULL):
  # видит и ведёт все текущие и будущие точки своей организации.
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

      @user = User.new(user_params.merge(tenant_id: nil, organization_id: org.id, status: "active"))
      role = Role.find_or_create_by!(code: "franchise_manager") { |r| r.name = "Franchise manager" }

      saved = false
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @user.save

        UserRole.find_or_create_by!(user: @user, role: role, tenant_id: nil)
        saved = true
      end

      if saved
        redirect_to platform_root_path, notice: "Владелец франшизы «#{org.name}» создан"
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
