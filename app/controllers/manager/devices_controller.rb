module Manager
  class DevicesController < BaseController
    before_action :require_privileged_manager!

    def index
      @devices = Device.for_current_tenant.order(created_at: :desc).limit(500)
      @new_device = Device.new(device_type: "tv_board", is_active: true, metadata: { "tv_mode" => Device::TV_MODE_ORDERS })
    end

    def create
      @new_device = Device.new(create_device_params)
      @new_device.tenant_id = Current.tenant_id
      @new_device.device_type = "tv_board"
      @new_device.is_active = true
      @new_device.device_token = SecureRandom.hex(24)
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

    def update_tv_mode
      @tv_device = Device.for_current_tenant.find(params[:id])
      unless @tv_device.device_type == "tv_board"
        redirect_to manager_devices_path, alert: "Только для TV-устройств"
        return
      end

      mode = params[:tv_mode].presence_in([Device::TV_MODE_ADS, Device::TV_MODE_ORDERS]) || Device::TV_MODE_ORDERS
      meta = (@tv_device.metadata || {}).stringify_keys
      meta["tv_mode"] = mode
      @tv_device.update!(metadata: meta)
      redirect_to manager_devices_path, notice: "Режим ТВ обновлён"
    end

    private

    def create_device_params
      params.require(:device).permit(:name)
    end
  end
end
