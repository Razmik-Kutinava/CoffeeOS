# frozen_string_literal: true

module Platform
  class PrepKitchenLinksController < BaseController
    before_action :set_kitchen

    def create
      authorize @kitchen, :update?

      sales_point = Tenant.find_by(id: params[:sales_point_tenant_id])
      unless sales_point&.sales_point?
        redirect_to platform_tenant_path(@kitchen), alert: "Выберите точку продаж"
        return
      end

      with_kitchen_rls do
        unless PrepKitchen::SalesPointRegistry.candidate_sales_points_for(@kitchen).exists?(id: sales_point.id)
          redirect_to platform_tenant_path(@kitchen), alert: "Точка недоступна для привязки"
          return
        end

        PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: sales_point)
      end

      redirect_to platform_tenant_path(@kitchen), notice: "Точка «#{sales_point.name}» привязана к цеху"
    rescue PrepKitchen::SalesPointRegistry::Error, ActiveRecord::RecordInvalid => e
      redirect_to platform_tenant_path(@kitchen), alert: e.message
    end

    def destroy
      authorize @kitchen, :update?

      point = Tenant.find_by(id: params[:sales_point_id])
      with_kitchen_rls do
        PrepKitchen::SalesPointRegistry.unlink!(
          prep_kitchen_tenant: @kitchen,
          sales_point_tenant_id: params[:sales_point_id]
        )
      end

      redirect_to platform_tenant_path(@kitchen),
                  notice: "Точка «#{point&.name || params[:sales_point_id]}» отвязана от цеха"
    end

    private

    def set_kitchen
      @kitchen = Tenant.find(params[:id])
      return if @kitchen.production_kitchen?

      redirect_to platform_tenant_path(@kitchen), alert: "Только для заготовочного цеха"
    end

    def with_kitchen_rls
      set_pg_context(tenant_id: @kitchen.id, user_id: current_user.id)
      yield
    ensure
      set_pg_context(user_id: current_user.id)
    end
  end
end
