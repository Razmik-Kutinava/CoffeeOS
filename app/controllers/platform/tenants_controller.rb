# frozen_string_literal: true

module Platform
  class TenantsController < BaseController
    def index
      authorize Tenant
      @tenants = Platform::UkCatalogScope.tenants
      @map_pins = Platform::TenantsMapPins.build(@tenants, url_helpers: self)
    end

    def new
      authorize Tenant
      @tenant = Tenant.new(organization_id: params[:organization_id], type: "sales_point", status: "active")
      build_default_weekday_schedules(@tenant)
    end

    def create
      authorize Tenant
      @tenant = Tenant.new(tenant_params)
      build_default_weekday_schedules(@tenant) unless @tenant.weekday_schedules.any?
      committed = false
      ActiveRecord::Base.transaction do
        unless @tenant.save
          raise ActiveRecord::Rollback
        end

        unless sync_weekday_schedules!
          raise ActiveRecord::Rollback
        end

        begin
          Platform::TenantOnboarding::Provision.call(
            tenant: @tenant,
            actor_user_id: current_user.id,
            module_params: module_params
          )
        rescue => e
          Rails.logger.error("TenantOnboarding::Provision failed: #{e.class} — #{e.message}")
          @tenant.errors.add(:base, "Не удалось инициализировать точку. Попробуйте ещё раз.")
          raise ActiveRecord::Rollback
        end

        unless sync_point_campaign!
          raise ActiveRecord::Rollback
        end
        committed = true
      end

      unless committed
        build_default_weekday_schedules(@tenant)
        return render(:new, status: :unprocessable_entity)
      end

      redirect_to platform_tenant_path(@tenant),
                  notice: "Точка создана"
    end

    def show
      @tenant = Tenant.includes(:organization, :feature_flags).find(params[:id])
      authorize @tenant
      @entry_points = Platform::TenantOnboarding::EntryPoints.for(
        @tenant,
        host: entry_points_host
      )
      load_card_binding_promo!
      load_prep_kitchen_links if @tenant.production_kitchen?
    end

    def edit
      @tenant = Tenant.includes(:organization, :feature_flags, :weekday_schedules).find(params[:id])
      authorize @tenant
      build_default_weekday_schedules(@tenant)
      @entry_points = Platform::TenantOnboarding::EntryPoints.for(
        @tenant,
        host: entry_points_host
      )
      load_card_binding_promo!
    end

    def update
      @tenant = Tenant.includes(:weekday_schedules).find(params[:id])
      authorize @tenant
      committed = false
      ActiveRecord::Base.transaction do
        unless @tenant.update(tenant_params)
          raise ActiveRecord::Rollback
        end

        unless sync_weekday_schedules!
          raise ActiveRecord::Rollback
        end

        begin
          Platform::TenantOnboarding::Provision.call(
            tenant: @tenant,
            actor_user_id: current_user.id,
            module_params: module_params
          )
        rescue => e
          Rails.logger.error("TenantOnboarding::Provision failed on update: #{e.class} — #{e.message}")
          @tenant.errors.add(:base, "Не удалось обновить настройки точки. Попробуйте ещё раз.")
          raise ActiveRecord::Rollback
        end

        unless sync_point_campaign!
          raise ActiveRecord::Rollback
        end
        committed = true
      end

      unless committed
        build_default_weekday_schedules(@tenant)
        @entry_points = Platform::TenantOnboarding::EntryPoints.for(
          @tenant,
          host: entry_points_host
        )
        load_card_binding_promo!
        return render(:edit, status: :unprocessable_entity)
      end

      redirect_to platform_tenant_path(@tenant), notice: "Сохранено"
    end

    def open_as_manager
      tenant = Tenant.find(params[:id])
      authorize tenant, :open_as_manager?
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
        :name, :slug, :organization_id, :type, :status, :city, :address,
        :latitude, :longitude,
        :country, :currency, :timezone
      )
    end

    def module_params
      params.fetch(:modules, ActionController::Parameters.new).permit(*TenantModuleFlags.modules)
    end

    def weekday_schedule_params
      day_permit = TenantWeekdaySchedule::WEEKDAYS.values.map(&:to_s).index_with { %i[enabled opens_at closes_at] }
      params.fetch(:weekday_schedules, ActionController::Parameters.new).permit(day_permit)
    end

    def sync_weekday_schedules!
      Platform::TenantWeekdaySchedulesSync.call(
        tenant: @tenant,
        schedule_params: weekday_schedule_params
      )
    end

    def point_campaign_params
      params.fetch(:point_campaign, ActionController::Parameters.new).permit(
        :card_binding_promo_enabled,
        :card_binding_promo_threshold
      )
    end

    # Sync promo for sales points when form sent keys; kitchens never keep enabled promo.
    def sync_point_campaign!
      if @tenant.production_kitchen?
        setting = PointCampaignSetting.card_binding_promo_for(@tenant.id)
        return true if setting.blank? || !setting.enabled?

        return Platform::PointCampaignSettingsSync.call(
          tenant: @tenant,
          enabled: false,
          threshold: setting.threshold
        )
      end

      raw = point_campaign_params
      return true if raw.blank?

      Platform::PointCampaignSettingsSync.call(
        tenant: @tenant,
        enabled: raw[:card_binding_promo_enabled],
        threshold: raw[:card_binding_promo_threshold]
      )
    end

    def load_card_binding_promo!
      return unless @tenant.sales_point?

      @card_binding_promo = PointCampaignSetting.card_binding_promo_for(@tenant.id)
      @card_binding_promo&.refresh_counter!
    end

    def build_default_weekday_schedules(tenant)
      return unless tenant.sales_point?

      TenantWeekdaySchedule::WEEKDAYS.each_value do |weekday|
        next if tenant.weekday_schedules.any? { |s| s.weekday == weekday }

        tenant.weekday_schedules.build(weekday: weekday, enabled: false)
      end
    end

    def entry_points_host
      ENV.fetch("APP_HOST", request.host_with_port)
    end

    def load_prep_kitchen_links
      set_pg_context(tenant_id: @tenant.id, user_id: current_user.id)
      @linked_sales_points = PrepKitchen::SalesPointRegistry.sales_points_for(@tenant.id)
      @candidate_sales_points = PrepKitchen::SalesPointRegistry.candidate_sales_points_for(@tenant)
    ensure
      set_pg_context(user_id: current_user.id)
    end
  end
end
