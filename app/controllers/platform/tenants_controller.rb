# frozen_string_literal: true

module Platform
  class TenantsController < BaseController
    def index
      @tenants = Tenant.includes(:organization).order(:name).limit(500)
    end

    def new
      @tenant = Tenant.new(organization_id: params[:organization_id], type: "sales_point", status: "active")
    end

    def create
      @tenant = Tenant.new(tenant_params)
      unless @tenant.save
        return render(:new, status: :unprocessable_entity)
      end

      ActiveRecord::Base.transaction do
        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_user_id = #{conn.quote(current_user.id.to_s)}")
        TenantModuleFlags.sync!(@tenant, module_params)
      end
      redirect_to platform_tenants_path, notice: "Точка создана"
    end

    def edit
      @tenant = Tenant.find(params[:id])
    end

    def update
      @tenant = Tenant.find(params[:id])
      unless @tenant.update(tenant_params)
        return render(:edit, status: :unprocessable_entity)
      end

      ActiveRecord::Base.transaction do
        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_user_id = #{conn.quote(current_user.id.to_s)}")
        TenantModuleFlags.sync!(@tenant, module_params)
      end
      redirect_to platform_tenants_path, notice: "Сохранено"
    end

    def open_as_manager
      tenant = Tenant.find(params[:id])
      session[:manager_tenant_id] = tenant.id.to_s
      redirect_to manager_dashboard_path, notice: "Панель менеджера: #{tenant.name}"
    end

    private

    def tenant_params
      params.require(:tenant).permit(
        :name, :slug, :organization_id, :type, :status, :city, :country, :currency, :timezone
      )
    end

    def module_params
      params.fetch(:modules, ActionController::Parameters.new).permit(*TenantModuleFlags.modules)
    end
  end
end
