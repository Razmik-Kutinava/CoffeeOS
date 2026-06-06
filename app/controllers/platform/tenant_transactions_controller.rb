# frozen_string_literal: true

module Platform
  # Drill-down «транзакции точки» — платежи для УК (§2A.4).
  class TenantTransactionsController < BaseController
    def show
      @tenant = Tenant.find(params[:id])
      @overview = TenantTransactionsOverview.new(
        @tenant,
        status: params[:status],
        method: params[:method]
      ).call
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
