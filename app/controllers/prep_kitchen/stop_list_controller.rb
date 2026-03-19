module PrepKitchen
  class StopListController < BaseController
    def index
      @reason = sanitize_reason(params[:reason])
      @items = ProductTenantSetting.where(tenant_id: Current.tenant_id, is_sold_out: true).includes(:product)
      @items = @items.where(sold_out_reason: @reason) if @reason != "all"
      if params[:q].present?
        q = "%#{params[:q].strip}%"
        @items = @items.joins(:product).where("products.name ILIKE ?", q)
      end
      @items = @items.order(updated_at: :desc).limit(300)
    end

    def update
      return no_rights unless prep_kitchen_manager?

      setting = ProductTenantSetting.where(tenant_id: Current.tenant_id).find(params[:id])
      if setting.update(stop_list_params)
        redirect_to prep_kitchen_stop_list_path, notice: "Стоп-лист обновлён"
      else
        redirect_to prep_kitchen_stop_list_path, alert: setting.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to prep_kitchen_stop_list_path, alert: "Запись не найдена"
    end

    private

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

    def no_rights
      redirect_to prep_kitchen_stop_list_path, alert: "Недостаточно прав"
    end
  end
end
