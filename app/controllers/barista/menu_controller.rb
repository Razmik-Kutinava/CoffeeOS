module Barista
  class MenuController < BaseController
    include MenuCatalogLoadable

    def index
      # Stage 1: view catalog + cart panel. Authorize create only when shift open
      # (same pattern as OrdersController#new — no redirect on missing shift).
      authorize Order, :create? if @shift
      load_tenant_menu!
      @cart = session[:barista_cart] || []
    end
  end
end
