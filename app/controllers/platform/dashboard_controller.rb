# frozen_string_literal: true

module Platform
  class DashboardController < BaseController
    def show
      @organizations = Organization.order(:name).limit(200)
      @tenants = Tenant.includes(:organization).left_joins(:organization)
        .order(Arel.sql("organizations.name NULLS LAST, tenants.name"))
        .limit(500)
    end
  end
end
