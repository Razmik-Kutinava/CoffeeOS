module Manager
  class TvBoardSettingsController < BaseController
    before_action :require_privileged_manager!

    def edit
      @tv_setting = tv_board_setting_for_current_tenant
    end

    def update
      @tv_setting = tv_board_setting_for_current_tenant

      if @tv_setting.update(tv_board_setting_params)
        redirect_to manager_tv_board_settings_path, notice: "Настройки ТВ обновлены"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def tv_board_setting_for_current_tenant
      TvBoardSetting.find_by(tenant_id: Current.tenant_id) ||
        TvBoardSetting.create!(
          tenant_id: Current.tenant_id,
          show_order_count: 10,
          display_seconds_ready: 60,
          theme: "dark"
        )
    end

    def tv_board_setting_params
      params.require(:tv_board_setting).permit(:show_order_count, :display_seconds_ready, :theme)
    end
  end
end

