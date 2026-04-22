class BroadcastTvColumnsJob < ApplicationJob
  queue_as :default

  # Рассылает обновление TV-колонок для всех активных TV-устройств тенанта.
  # Принимает tenant_id явно, чтобы не зависеть от Current.tenant_id в контексте джоба.
  def perform(tenant_id)
    tv_setting = TvBoardSetting.find_by(tenant_id: tenant_id) ||
      TvBoardSetting.create!(
        tenant_id: tenant_id,
        show_order_count: 10,
        display_seconds_ready: 60,
        theme: 'dark'
      )

    Device.where(tenant_id: tenant_id, device_type: "tv_board", is_active: true).find_each do |device|
      effective = device.tv_effective_show_order_count(tv_setting)
      stream    = "tv_orders_#{device.id}"

      Turbo::StreamsChannel.broadcast_replace_to(
        stream,
        target: "tv-ads-area",
        partial: "tv_board/ads_area",
        locals: { tv_setting: tv_setting, effective_limit: effective }
      )

      accepted_orders  = effective > 0 ? orders_for_column(tenant_id, "accepted",  effective) : Order.none
      preparing_orders = effective > 0 ? orders_for_column(tenant_id, "preparing", effective) : Order.none
      ready_orders     = effective > 0 ? orders_for_column(tenant_id, "ready",     effective) : Order.none

      Turbo::StreamsChannel.broadcast_replace_to(
        stream,
        target: "tv-orders-accepted",
        partial: "tv_board/orders_column",
        locals: { status: "accepted", orders: accepted_orders, tv_setting: tv_setting }
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        stream,
        target: "tv-orders-preparing",
        partial: "tv_board/orders_column",
        locals: { status: "preparing", orders: preparing_orders, tv_setting: tv_setting }
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        stream,
        target: "tv-orders-ready",
        partial: "tv_board/orders_column",
        locals: { status: "ready", orders: ready_orders, tv_setting: tv_setting }
      )
    end
  end

  private

  def orders_for_column(tenant_id, status, limit)
    Order.for_barista_board(tenant_id)
         .where(status: status)
         .order(created_at: :asc)
         .limit(limit)
  end
end
