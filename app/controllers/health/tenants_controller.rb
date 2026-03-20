# frozen_string_literal: true

# JSON health: только ук_global_admin (сессия + cookie).
module Health
  class TenantsController < ApplicationController
    layout false
    before_action :require_uk_global_admin

    def index
      tenants = Tenant.where(status: "active").order(:name)
      data = tenants.map do |tenant|
        result = Health::TenantChecker.new(tenant).call
        {
          id: tenant.id,
          name: tenant.name,
          slug: tenant.slug,
          status: tenant.status,
          organization_id: tenant.organization_id,
          overall: result[:overall],
          checks: result[:checks]
        }
      end
      render json: { tenants: data, generated_at: Time.current.iso8601 }
    end

    def show
      tenant = Tenant.find(params[:id])
      result = Health::TenantChecker.new(tenant).call
      render json: {
        tenant: {
          id: tenant.id,
          name: tenant.name,
          slug: tenant.slug,
          organization_id: tenant.organization_id
        },
        checks: result[:checks],
        overall: result[:overall],
        generated_at: Time.current.iso8601
      }
    end

    private

    def require_uk_global_admin
      u = session[:user_id] && User.find_by(id: session[:user_id])
      head :unauthorized unless u&.uk_global_admin?
    end
  end
end
