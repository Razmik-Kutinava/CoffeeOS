module Manager
  class DevicesController < BaseController
    before_action :require_office_manager_only

    def index
      @devices = Device.for_current_tenant.order(created_at: :desc).limit(500)
    end

    private

    def require_office_manager_only
      return if office_manager?

      redirect_to manager_dashboard_path, alert: "Доступ запрещён"
    end
  end
end

