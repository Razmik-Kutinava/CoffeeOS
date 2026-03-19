# frozen_string_literal: true

# API для мониторинга здоровья точек. Возвращает JSON.
# Используется центральной админкой для дашборда.
# TODO: добавить авторизацию (токен, superadmin) перед выкладкой в прод.
module Health
  class TenantsController < ActionController::API
    def index
      tenants = Tenant.where(status: "active").order(:name)
      data = tenants.map do |tenant|
        result = Health::TenantChecker.new(tenant).call
        {
          id: tenant.id,
          name: tenant.name,
          slug: tenant.slug,
          status: tenant.status,
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
        tenant: { id: tenant.id, name: tenant.name, slug: tenant.slug },
        checks: result[:checks],
        overall: result[:overall],
        generated_at: Time.current.iso8601
      }
    end
  end
end
