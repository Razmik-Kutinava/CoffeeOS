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
      @generated_at = Time.current
    end
  end
end
