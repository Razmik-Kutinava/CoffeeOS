class TvBoardsController < ApplicationController
  def show
    token = params[:token].presence
    return head :forbidden if token.blank?

    policy = TvBoardPolicy.new(token: token)
    return head :not_found unless policy.show?

    device = policy.device
    @device = device

    # Нужен токен для ActionCable соединения (без user login).
    cookies[:tv_device_token] = {
      value: device.device_token,
      httponly: true,
      same_site: :lax,
      expires: 1.day
    }

    Current.tenant_id = device.tenant_id
    Current.user_id = nil
    Current.role_code = "tv_board"

    conn = ActiveRecord::Base.connection
    conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(Current.tenant_id.to_s)}")

    @tv_setting = tv_board_setting_for_current_tenant
    @effective_limit = @device.tv_effective_show_order_count(@tv_setting)

    @accepted_orders = @effective_limit > 0 ? tv_orders_for_status("accepted", @effective_limit) : []
    @preparing_orders = @effective_limit > 0 ? tv_orders_for_status("preparing", @effective_limit) : []
    @ready_orders = @effective_limit > 0 ? tv_orders_for_status("ready", @effective_limit) : []

    render "tv_board/show"
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

  def tv_orders_for_status(status, limit)
    shift = CashShift.find_by(tenant_id: Current.tenant_id, status: "open")
    scope = Barista::BoardOrdersQuery.board_scope(tenant_id: Current.tenant_id, cash_shift: shift)
    scope.where(status: status)
         .order(created_at: :asc)
         .limit(limit)
         .select(:id, :order_number, :created_at, :status)
         .to_a
  end
end
