# frozen_string_literal: true

module Platform
  class DashboardController < BaseController
    def show
      @organizations = Platform::UkCatalogScope.organizations
      @tenants = Platform::UkCatalogScope.tenants
        .left_joins(:organization)
        .reorder(Arel.sql("organizations.name NULLS LAST, tenants.name"))
    end
  end
end
