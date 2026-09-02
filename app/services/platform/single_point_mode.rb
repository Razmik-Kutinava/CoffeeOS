# frozen_string_literal: true

module Platform
  # Канон одной боевой точки (Point A) — см. ProdSinglePointCleanup, fly.toml DEMO_SINGLE_POINT.
  module SinglePointMode
    POINT_A_TENANT_ID = ProdSinglePointCleanup::POINT_A_TENANT_ID
    POINT_A_SLUG = ProdSinglePointCleanup::POINT_A_SLUG

    module_function

    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_SINGLE_POINT", "false"))
    end

    def point_a
      Tenant.find_by(id: POINT_A_TENANT_ID) || Tenant.find_by(slug: POINT_A_SLUG)
    end
  end
end
