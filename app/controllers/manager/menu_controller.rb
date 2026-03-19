module Manager
  class MenuController < BaseController
    def index
      @settings = ProductTenantSetting
        .where(tenant_id: Current.tenant_id)
        .includes(:product)
        .order("product_id ASC")
        .limit(500)
    end
  end
end

