# frozen_string_literal: true

require "test_helper"

class Platform::TenantOnboarding::CatalogBootstrapTest < ActiveSupport::TestCase
  include TestFactories

  test "ensure_pts_for_tenant! creates only missing PTS for active products" do
    org = create_organization!
    t1 = create_tenant!(organization: org, slug: "t1-#{SecureRandom.hex(2)}")
    t2 = create_tenant!(organization: org, slug: "t2-#{SecureRandom.hex(2)}")
    cat = create_category!
    p1 = create_product!(category: cat, name: "Latte", slug: "latte-#{SecureRandom.hex(2)}")
    p1.update!(base_price: 150)

    enable_product_for_tenant!(tenant: t1, product: p1, price: 99)

    ActiveRecord::Base.transaction do
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL app.current_user_id = #{conn.quote(SecureRandom.uuid)}")
      conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(t2.id.to_s)}")
      Current.tenant_id = t2.id
      Platform::TenantOnboarding::CatalogBootstrap.ensure_pts_for_tenant!(t2)
    ensure
      Current.tenant_id = nil
    end

    pts = ProductTenantSetting.find_by(tenant_id: t2.id, product_id: p1.id)
    assert pts
    assert_equal BigDecimal("150"), pts.price
    assert_equal Product.where(is_active: true).count, ProductTenantSetting.where(tenant_id: t2.id).count
    assert_equal 1, ProductTenantSetting.where(tenant_id: t1.id).count
  end
end
