# frozen_string_literal: true

module Platform
  # Сводка и drill-down мониторинга всех точек для УК.
  class MonitoringController < BaseController
    def index
      @tenants = Tenant.where(status: "active").includes(:organization).order(:name)
      @summaries = @tenants.map do |tenant|
        result = Health::TenantChecker.new(tenant).call
        { tenant: tenant, overall: result[:overall], checks: result[:checks] }
      end
      @generated_at = Time.current
    end

    def show
      @tenant = Tenant.find(params[:id])
      @result = Health::TenantChecker.new(@tenant, include_events: true).call
      @feed = Health::TenantEventFeed.new(@tenant).call
      @generated_at = Time.current
    end

    def events
      tenant = Tenant.find(params[:id])
      feed = Health::TenantEventFeed.new(tenant).call
      render json: {
        tenant: { id: tenant.id, name: tenant.name, slug: tenant.slug },
        check_details: feed[:check_details],
        unified_feed: feed[:unified_feed],
        generated_at: Time.current.iso8601
      }
    end
  end
end
