# frozen_string_literal: true

module Platform
  # Списки УК «Code Black»: все организации-франчайзи и все их точки (продажи, цеха, неактивные).
  class UkCatalogScope
    def self.tenants
      Tenant.includes(:organization).order(:name).limit(500)
    end

    def self.organizations
      Organization.order(:name).limit(200)
    end
  end
end
