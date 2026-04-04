# frozen_string_literal: true

module Shop
  class PagesController < Shop::BaseController
    layout "shop"

    def home
      tid = resolved_shop_tenant_id
      @shop_tenant = Tenant.find_by(id: tid) if tid.present?
    end
  end
end
