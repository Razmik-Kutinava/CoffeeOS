# frozen_string_literal: true

module Shop
  # B1.14-3b: дропдаун в шапке — все активные точки в том же городе;
  # порядок: текущая → ближайшие по координатам → без координат (по имени).
  class CustomerTenantHistory
    def self.call(session:, current_tenant:)
      new(session: session, current_tenant: current_tenant).call
    end

    def initialize(session:, current_tenant:)
      @session = session
      @current_tenant = current_tenant
    end

    def call
      rows = sorted_city_rows
      {
        current_tenant_id: @current_tenant.id,
        last_ordered_tenant_id: last_ordered_tenant_id,
        switchable: rows.size > 1,
        tenants: rows
      }
    end

    private

    def sorted_city_rows
      peers = city_sales_points
      # Неактивную / чужую текущую точку не впихиваем в дропдаун —
      # иначе sticky Fly Overnight (inactive) держит витрину без «повторить».
      if current_tenant_switchable?
        peers = (peers + [@current_tenant]).uniq(&:id)
      elsif peers.empty?
        return []
      end

      current = peers.find { |t| t.id == @current_tenant.id } || peers.first
      others = peers.reject { |t| t.id == current.id }

      with_coords, without_coords = others.partition { |t| TenantGeo.coordinates?(t) }

      if TenantGeo.coordinates?(current)
        with_coords.sort_by! { |t| TenantGeo.distance_km(current, t) || Float::INFINITY }
      else
        with_coords.sort_by!(&:name)
      end
      without_coords.sort_by!(&:name)

      ([current] + with_coords + without_coords).map { |t| tenant_row(t) }
    end

    def current_tenant_switchable?
      @current_tenant.status.to_s == "active" && @current_tenant.type.to_s == "sales_point"
    end

    def city_sales_points
      city_key = TenantGeo.normalize_city(@current_tenant.city)
      return [] if city_key.blank?

      with_rls_off do
        Tenant.where(status: "active", type: "sales_point").select do |t|
          TenantGeo.normalize_city(t.city) == city_key
        end
      end
    end

    def last_ordered_tenant_id
      cid = CustomerSession.customer_id(@session, @current_tenant.id)
      return nil if cid.blank?

      stats = with_rls_off do
        Order.mobile.where(customer_id: cid).group(:tenant_id).maximum(:created_at)
      end
      return nil if stats.blank?

      stats.max_by { |_tid, at| at }&.first
    end

    def tenant_row(tenant)
      TenantAddress.client_json(tenant).merge(
        is_current: tenant.id == @current_tenant.id,
        distance_km: distance_for_client(tenant)
      )
    end

    def distance_for_client(tenant)
      return nil if tenant.id == @current_tenant.id
      return nil unless TenantGeo.coordinates?(@current_tenant) && TenantGeo.coordinates?(tenant)

      km = TenantGeo.distance_km(@current_tenant, tenant)
      km.nil? ? nil : km.round(2)
    end

    def with_rls_off
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL row_security = off")
      yield
    end
  end
end
