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
      committed = false
      ActiveRecord::Base.transaction do
        unless @tenant.save
          raise ActiveRecord::Rollback
        end

        begin
          Platform::TenantOnboarding::Provision.call(
            tenant: @tenant,
            actor_user_id: current_user.id,
            module_params: module_params
          )
          committed = true
        rescue => e
          Rails.logger.error("TenantOnboarding::Provision failed: #{e.class} — #{e.message}")
          @tenant.errors.add(:base, "Не удалось инициализировать точку. Попробуйте ещё раз.")
          raise ActiveRecord::Rollback
        end
      end

      unless committed
        return render(:new, status: :unprocessable_entity)
      end

      redirect_to platform_tenant_path(@tenant),
                  notice: "Точка создана"
    end

    def show
      @tenant = Tenant.includes(:organization, :feature_flags).find(params[:id])
      @entry_points = Platform::TenantOnboarding::EntryPoints.for(
        @tenant,
        host: entry_points_host
      )
    end

    def edit
      @tenant = Tenant.includes(:organization, :feature_flags).find(params[:id])
      @entry_points = Platform::TenantOnboarding::EntryPoints.for(
        @tenant,
        host: entry_points_host
      )
    end

    def update
      @tenant = Tenant.find(params[:id])
      committed = false
      ActiveRecord::Base.transaction do
        unless @tenant.update(tenant_params)
          raise ActiveRecord::Rollback
        end

        begin
          Platform::TenantOnboarding::Provision.call(
            tenant: @tenant,
            actor_user_id: current_user.id,
            module_params: module_params
          )
          committed = true
        rescue => e
          Rails.logger.error("TenantOnboarding::Provision failed on update: #{e.class} — #{e.message}")
          @tenant.errors.add(:base, "Не удалось обновить настройки точки. Попробуйте ещё раз.")
          raise ActiveRecord::Rollback
        end
      end

      unless committed
        @entry_points = Platform::TenantOnboarding::EntryPoints.for(
          @tenant,
          host: entry_points_host
        )
        return render(:edit, status: :unprocessable_entity)
      end

      redirect_to platform_tenant_path(@tenant), notice: "Сохранено"
    end

    def open_as_manager
      tenant = Tenant.find(params[:id])
      session[:manager_tenant_id] = tenant.id.to_s
      destination =
        case params[:to].to_s
        when "staff" then manager_staff_members_path
        else manager_dashboard_path
        end
      redirect_to destination, notice: "Панель менеджера: #{tenant.name}"
    end

    private

    def tenant_params
      params.require(:tenant).permit(
        :name, :slug, :organization_id, :type, :status, :city, :address, :country, :currency, :timezone
      )
    end

    def module_params
      params.fetch(:modules, ActionController::Parameters.new).permit(*TenantModuleFlags.modules)
    end

    def entry_points_host
      ENV.fetch("APP_HOST", request.host_with_port)
    end
  end
end
