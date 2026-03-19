module Manager
  class StaffController < BaseController
    before_action :require_office_manager_only

    def index
      @users = User.for_tenant(Current.tenant_id).includes(:roles).order(:name).limit(500)
      @roles = Role.order(:code)
    end

    private

    def require_office_manager_only
      return if office_manager?

      redirect_to manager_dashboard_path, alert: "Доступ запрещён"
    end
  end
end

