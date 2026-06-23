# frozen_string_literal: true

module Shop
  # B1.14: точки продаж, где покупатель уже заказывал (дропдаун в шапке).
  class CustomerTenantHistory
    def self.call(session:, current_tenant:)
      new(session: session, current_tenant: current_tenant).call
    end

    def initialize(session:, current_tenant:)
      @session = session
      @current_tenant = current_tenant
    end

    def call
      cid = CustomerSession.customer_id(@session, @current_tenant.id)
      return guest_payload if cid.blank?

      rows = ordered_tenant_rows(cid)
      return guest_payload if rows.empty?

      {
        current_tenant_id: @current_tenant.id,
        last_ordered_tenant_id: rows.first[:id],
        switchable: rows.size > 1,
        tenants: rows
      }
    end

    private

    def guest_payload
      {
        current_tenant_id: @current_tenant.id,
        last_ordered_tenant_id: nil,
        switchable: false,
        tenants: [tenant_row(@current_tenant, last_ordered_at: nil)]
      }
    end

    def ordered_tenant_rows(customer_id)
      stats = tenant_order_stats(customer_id)
      return [] if stats.empty?

      tenants = Tenant.where(id: stats.keys, type: "sales_point").index_by { |t| t.id.to_s }
      stats.filter_map do |tid, last_at|
        tenant = tenants[tid]
        next unless tenant

        tenant_row(tenant, last_ordered_at: last_at)
      end.sort_by { |row| row[:last_ordered_at].to_s }.reverse
    end

    # RLS off: только tenant_id заказов этого customer_id (публичные поля точки).
    def tenant_order_stats(customer_id)
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL row_security = off")
      Order.mobile.where(customer_id: customer_id).group(:tenant_id).maximum(:created_at)
    end

    def tenant_row(tenant, last_ordered_at:)
      TenantAddress.client_json(tenant).merge(
        last_ordered_at: last_ordered_at&.iso8601,
        is_current: tenant.id == @current_tenant.id
      )
    end
  end
end
