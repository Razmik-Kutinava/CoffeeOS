module Manager
  class MenuController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize ProductTenantSetting, :index?
      @settings = ProductTenantSetting
        .where(tenant_id: Current.tenant_id)
        .includes(:product)
        .order("product_id ASC")
        .limit(500)
    end

    def update_price
      authorize ProductTenantSetting, :update?
      setting = ProductTenantSetting.where(tenant_id: Current.tenant_id).find(params[:id])

      if setting.update(price_params)
        Platform::Menu::ProductTenantSync.bust_shop_catalog_cache!(tenant_ids: [ Current.tenant_id ])
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
