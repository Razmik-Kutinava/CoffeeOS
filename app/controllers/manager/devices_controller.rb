module Manager
  class DevicesController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized
    before_action :require_privileged_manager!

    def index
      authorize Device, :index?
      @devices = Device.for_current_tenant.order(created_at: :desc).limit(500)
      @new_device = Device.new(device_type: "tv_board", is_active: true, metadata: { "tv_mode" => Device::TV_MODE_ORDERS })
    end

    def create
      authorize Device, :create?
      @new_device = Device.new(create_device_params)
      @new_device.tenant_id = Current.tenant_id
      @new_device.device_type = "tv_board"
      @new_device.is_active = true
      Devices::TokenCredentials.apply_attributes!(device: @new_device)
      @new_device.metadata = (@new_device.metadata.presence || {}).stringify_keys
      @new_device.metadata["tv_mode"] ||= Device::TV_MODE_ORDERS

      if @new_device.save
        redirect_to manager_devices_path,
                    notice: "TV создан. Откройте: /tv_board?token=#{@new_device.device_token}"
      else
        @devices = Device.for_current_tenant.order(created_at: :desc).limit(500)
        flash.now[:alert] = @new_device.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def create_kiosk
      authorize Device, :create_kiosk?
      @new_kiosk = Device.new(name: params.dig(:device, :name).to_s.strip)
      @new_kiosk.tenant_id   = Current.tenant_id
      @new_kiosk.device_type = "kiosk"
      @new_kiosk.is_active   = true
      Devices::TokenCredentials.apply_attributes!(device: @new_kiosk)

      if @new_kiosk.save
        redirect_to manager_devices_path,
                    notice: "Киоск «#{@new_kiosk.name}» создан. Токен: #{@new_kiosk.device_token}"
      else
        @devices    = Device.for_current_tenant.order(created_at: :desc).limit(500)
        @new_device = Device.new(device_type: "tv_board", is_active: true)
        flash.now[:alert] = @new_kiosk.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def update_tv_mode
      @tv_device = Device.for_current_tenant.find(params[:id])
      authorize @tv_device, :update_tv_mode?
      unless @tv_device.device_type == "tv_board"
        redirect_to manager_devices_path, alert: "Только для TV-устройств"
        return
      end

      mode = params[:tv_mode].presence_in([ Device::TV_MODE_ADS, Device::TV_MODE_ORDERS ]) || Device::TV_MODE_ORDERS
      meta = (@tv_device.metadata || {}).stringify_keys
      meta["tv_mode"] = mode
      @tv_device.update!(metadata: meta)
      redirect_to manager_devices_path, notice: "Режим ТВ обновлён"
    end

    def revoke
      device = Device.for_current_tenant.find(params[:id])
      authorize device, :revoke?
      device.update!(is_active: false)
      redirect_to manager_devices_path, notice: "Устройство «#{device.name}» отключено. Токен больше не принимается."
    end

    def rotate_token
      device = Device.for_current_tenant.find(params[:id])
      authorize device, :rotate_token?
      was_inactive = !device.is_active?
      new_token = Devices::TokenRotation.call!(device: device)
      notice =
        if device.device_type == "tv_board"
          prefix = was_inactive ? "Устройство восстановлено. " : ""
          "#{prefix}Новый токен TV. Обновите URL: /tv_board?token=#{new_token}"
        else
          prefix = was_inactive ? "Устройство восстановлено. " : ""
          "#{prefix}Новый токен киоска: #{new_token}"
        end
      redirect_to manager_devices_path, notice: notice
    end

    private

    def create_device_params
      params.require(:device).permit(:name)
    end
  end
end
