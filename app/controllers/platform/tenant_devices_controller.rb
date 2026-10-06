# frozen_string_literal: true

module Platform
  # ТВ-табло точки прямо из карточки УК (без «открыть как менеджер»).
  class TenantDevicesController < BaseController
    before_action :set_tenant

    def create
      authorize @tenant, :update?
      unless TenantModuleFlags.enabled?(@tenant.id, :tv_board)
        return redirect_to platform_tenant_path(@tenant), alert: "Модуль «TV-борд» выключен — включите его в настройках точки"
      end

      device = Device.new(
        tenant_id: @tenant.id,
        device_type: "tv_board",
        name: params.dig(:device, :name).to_s.strip,
        metadata: { "tv_mode" => Device::TV_MODE_ORDERS }
      )
      Devices::TokenCredentials.apply_attributes!(device: device)

      saved = with_tenant_rls { device.save }
      if saved
        redirect_to platform_tenant_path(@tenant), notice: "ТВ «#{device.name}» создан: /tv_board?token=#{device.device_token}"
      else
        redirect_to platform_tenant_path(@tenant), alert: device.errors.full_messages.to_sentence
      end
    end

    def revoke
      authorize @tenant, :update?
      revoked = with_tenant_rls do
        device = Device.find_by(id: params[:id], tenant_id: @tenant.id, device_type: "tv_board")
        device&.update!(is_active: false)
      end
      return head :not_found unless revoked

      redirect_to platform_tenant_path(@tenant), notice: "ТВ отключён, токен больше не принимается"
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:tenant_id])
    end

    def with_tenant_rls
      ActiveRecord::Base.transaction do
        set_pg_context(tenant_id: @tenant.id, user_id: current_user.id)
        yield
      end
    end
  end
end
