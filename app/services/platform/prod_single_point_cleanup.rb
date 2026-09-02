# frozen_string_literal: true

module Platform
  # Деактивирует лишние sales_point на стенде, оставляя одну боевую точку (Point A).
  # Данные заказов/карт не удаляются — только status → inactive на лишних точках.
  class ProdSinglePointCleanup
    POINT_A_TENANT_ID = "2fdee1ac-4674-41ee-b89e-87b45643f789"
    POINT_A_SLUG = "demo-point-a"
    POINT_A_ADDRESS = "ул. Ленина, 10"
    POINT_A_CITY = "Москва"

    Result = Struct.new(
      :dry_run,
      :point_a,
      :kept_tenant_ids,
      :deactivated,
      :already_inactive,
      :skipped,
      :verification,
      :before,
      keyword_init: true
    )

    def self.call(dry_run: true, keep_tenant_ids: nil, keep_kitchen: true, point_a_id: nil)
      new(
        dry_run: dry_run,
        keep_tenant_ids: keep_tenant_ids,
        keep_kitchen: keep_kitchen,
        point_a_id: point_a_id
      ).call
    end

    def initialize(dry_run:, keep_tenant_ids:, keep_kitchen:, point_a_id:)
      @dry_run = dry_run
      @keep_tenant_ids = Array(keep_tenant_ids).map(&:to_s).presence
      @keep_kitchen = keep_kitchen
      @point_a_id = point_a_id
    end

    def call
      point_a = resolve_point_a!
      keep_ids = build_keep_ids(point_a)
      before = snapshot(point_a)

      deactivated = []
      already_inactive = []
      skipped = []

      Tenant.where(type: "sales_point").order(:slug).find_each do |tenant|
        if keep_ids.include?(tenant.id.to_s)
          skipped << tenant_summary(tenant, reason: "keep")
          next
        end

        if tenant.status.to_s == "inactive"
          already_inactive << tenant_summary(tenant)
          next
        end

        unless @dry_run
          tenant.update!(status: "inactive")
        end
        deactivated << tenant_summary(tenant)
      end

      ensure_point_a_profile!(point_a) unless @dry_run

      after = snapshot(point_a)
      verification = verify!(point_a, before, after, keep_ids)

      Result.new(
        dry_run: @dry_run,
        point_a: tenant_summary(point_a),
        kept_tenant_ids: keep_ids,
        deactivated: deactivated,
        already_inactive: already_inactive,
        skipped: skipped,
        verification: verification,
        before: before
      )
    end

    private

    def resolve_point_a!
      if @point_a_id.present?
        tenant = Tenant.find_by(id: @point_a_id)
        raise "Point A not found (id=#{@point_a_id})" unless tenant

        return tenant
      end

      by_id = Tenant.find_by(id: POINT_A_TENANT_ID)
      return by_id if by_id

      by_slug = Tenant.find_by(slug: POINT_A_SLUG)
      return by_slug if by_slug

      raise "Point A not found (id=#{POINT_A_TENANT_ID}, slug=#{POINT_A_SLUG})"
    end

    def build_keep_ids(point_a)
      ids = @keep_tenant_ids || [ point_a.id.to_s ]
      ids = ids.map(&:to_s).uniq

      if @keep_kitchen && point_a.organization_id.present?
        kitchen_ids = Tenant.where(
          organization_id: point_a.organization_id,
          type: "production_kitchen",
          status: "active"
        ).pluck(:id).map(&:to_s)
        ids |= kitchen_ids
      end

      ids
    end

    def ensure_point_a_profile!(point_a)
      updates = {}
      updates[:address] = POINT_A_ADDRESS if point_a.address.blank?
      updates[:city] = POINT_A_CITY if point_a.city.blank?
      updates[:status] = "active" unless point_a.status.to_s == "active"
      point_a.update!(updates) if updates.present?
    end

    def snapshot(point_a)
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL row_security = off")

      {
        active_sales_points: Tenant.where(status: "active", type: "sales_point").order(:slug).pluck(:slug, :id),
        point_a_orders: Order.where(tenant_id: point_a.id).count,
        point_a_payments: Payment.where(tenant_id: point_a.id).count,
        point_a_pts: ProductTenantSetting.where(tenant_id: point_a.id).count
      }
    end

    def verify!(point_a, before, after, keep_ids)
      active_sales = Tenant.where(status: "active", type: "sales_point")
      checks = {
        point_a_active: point_a.reload.status.to_s == "active",
        orders_preserved: after[:point_a_orders] == before[:point_a_orders],
        payments_preserved: after[:point_a_payments] == before[:point_a_payments],
        pts_preserved: after[:point_a_pts] == before[:point_a_pts],
        active_kitchens: Tenant.where(type: "production_kitchen", status: "active").count
      }
      unless @dry_run
        checks[:single_active_sales_point] =
          active_sales.count == 1 && active_sales.first.id == point_a.id
      end
      checks[:pass] = checks.values.all?
      checks
    end

    def tenant_summary(tenant, reason: nil)
      row = {
        id: tenant.id,
        slug: tenant.slug,
        name: tenant.name,
        type: tenant.type,
        status: tenant.status
      }
      row[:reason] = reason if reason
      row
    end
  end
end
