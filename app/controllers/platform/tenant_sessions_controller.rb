# frozen_string_literal: true

module Platform
  # Drill-down «сессии точки» — кто онлайн, все пользователи, входы (§2A.3).
  class TenantSessionsController < BaseController
    def show
      @tenant = Tenant.find(params[:id])
      @overview = TenantSessionsOverview.new(@tenant).call
      @generated_at = Time.current

      respond_to do |format|
        format.html
        format.json do
          render json: @overview.merge(generated_at: @generated_at.iso8601)
        end
      end
    end
  end
end
