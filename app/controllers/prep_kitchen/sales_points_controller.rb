# frozen_string_literal: true

module PrepKitchen
  class SalesPointsController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize SalesPointLink, :index?
      @kitchen = Tenant.find(Current.tenant_id)
      @linked_sales_points = SalesPointRegistry.sales_points_for(Current.tenant_id)
      @candidate_sales_points = SalesPointRegistry.candidate_sales_points_for(@kitchen)
    end

    def create
      authorize SalesPointLink, :create?
      kitchen = Tenant.find(Current.tenant_id)
      sales_point = Tenant.find_by(id: params[:sales_point_tenant_id])

      unless sales_point&.sales_point?
        redirect_to prep_kitchen_sales_points_path, alert: "Выберите точку продаж"
        return
      end

      SalesPointRegistry.link!(prep_kitchen_tenant: kitchen, sales_point_tenant: sales_point)
      redirect_to prep_kitchen_sales_points_path, notice: "Точка «#{sales_point.name}» привязана к цеху"
    rescue SalesPointRegistry::Error, ActiveRecord::RecordInvalid => e
      redirect_to prep_kitchen_sales_points_path, alert: e.message
    end

    def destroy
      authorize SalesPointLink, :destroy?
      kitchen = Tenant.find(Current.tenant_id)
      point = Tenant.find_by(id: params[:id])
      SalesPointRegistry.unlink!(prep_kitchen_tenant: kitchen, sales_point_tenant_id: params[:id])
      redirect_to prep_kitchen_sales_points_path,
                  notice: "Точка «#{point&.name || params[:id]}» отвязана от цеха"
    end
  end
end
