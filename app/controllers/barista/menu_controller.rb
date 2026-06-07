module Barista
  class MenuController < BaseController
    include MenuCatalogLoadable

    def index
      load_tenant_menu!
    end
  end
end
