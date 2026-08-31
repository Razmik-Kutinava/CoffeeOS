module PrepKitchen
  class StopListController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize :prep_kitchen_stop_list, :index?, policy_class: PrepKitchen::StopListPolicy
      @reason = sanitize_reason(params[:reason])
      @linked_sales_points = SalesPointRegistry.sales_points_for(Current.tenant_id)
      @items = StopList::LinkedSalesPointSettingsQuery.call(
        prep_kitchen_tenant_id: Current.tenant_id,
        reason: @reason,
        q: params[:q],
        user_id: Current.user_id
      )
    end

    def update
      authorize :prep_kitchen_stop_list, :update?, policy_class: PrepKitchen::StopListPolicy

      setting = find_linked_setting(params[:id])
      unless setting
        redirect_to prep_kitchen_stop_list_path, alert: "Запись не найдена"
        return
      end

      updated = false
      errors = nil
      LinkedTenantScope.with_linked_sales_point(
        prep_kitchen_tenant_id: Current.tenant_id,
        sales_point_tenant_id: setting.tenant_id,
        user_id: Current.user_id
      ) do
        record = ProductTenantSetting.where(tenant_id: setting.tenant_id).find(setting.id)
        updated = record.update(stop_list_params)
        errors = record.errors.full_messages.join(", ") unless updated
      end

      if updated
        redirect_to prep_kitchen_stop_list_path, notice: "Стоп-лист обновлён"
      else
        redirect_to prep_kitchen_stop_list_path, alert: errors.presence || "Не удалось обновить стоп-лист"
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to prep_kitchen_stop_list_path, alert: "Запись не найдена"
    end

    private

    def find_linked_setting(id)
      LinkedTenantScope.flat_map(prep_kitchen_tenant_id: Current.tenant_id, user_id: Current.user_id) do |tenant_id|
        ProductTenantSetting.where(tenant_id: tenant_id, id: id).includes(:product, :tenant).first
      end.compact.first
    end

    def stop_list_params
      attrs = params.require(:product_tenant_setting).permit(:is_sold_out, :sold_out_reason)
      if ActiveModel::Type::Boolean.new.cast(attrs[:is_sold_out]) && attrs[:sold_out_reason].blank?
        attrs[:sold_out_reason] = "manual"
      elsif !ActiveModel::Type::Boolean.new.cast(attrs[:is_sold_out])
        attrs[:sold_out_reason] = nil
      end
      attrs
    end

    def sanitize_reason(value)
      allowed = %w[all manual stock_empty]
      allowed.include?(value) ? value : "all"
    end
  end
end
