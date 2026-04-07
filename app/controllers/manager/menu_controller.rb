module Manager
  class MenuController < BaseController
    def index
      @settings = ProductTenantSetting
        .where(tenant_id: Current.tenant_id)
        .includes(:product)
        .order("product_id ASC")
        .limit(500)
    end

    def update_price
      return redirect_to(manager_menu_path, alert: "Недостаточно прав") unless office_or_franchise_manager?

      setting = ProductTenantSetting.where(tenant_id: Current.tenant_id).find(params[:id])

      if setting.update(price_params)
        redirect_to manager_menu_path, notice: "Цена обновлена"
      else
        redirect_to manager_menu_path, alert: setting.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to manager_menu_path, alert: "Запись не найдена"
    end

    private

    def price_params
      params.require(:product_tenant_setting).permit(:price)
    end
  end
end

