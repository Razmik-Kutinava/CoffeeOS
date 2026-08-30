module Barista
  class OrdersController < BaseController
    include MenuCatalogLoadable
    def show
      return redirect_no_open_shift unless current_shift

      @order = shift_accessible_orders.includes(:payments).find(params[:id])
      authorize @order
      @order_items = @order.order_items.includes(:product)

      respond_to do |format|
        format.html
        format.json do
          render json: {
            id: @order.id,
            order_number: @order.order_number,
            status: @order.status,
            source: @order.source,
            final_amount: @order.final_amount,
            payment_status: @order.payments.first&.status || "not_paid",
            order_items: @order.order_items.map do |item|
              {
                product_name: item.product_name,
                quantity: item.quantity,
                price: item.unit_price,
                total_price: item.total_price,
                modifiers: Array(item.modifier_options&.dig("selected_modifiers")).map { |m| m["name"] }
              }
            end
          }
        end
      end
    end

    def history
      authorize Order, :history?
      @orders = Order.for_current_tenant
                    .where(status: [ "closed", "cancelled", "issued" ])
                    .includes(:order_items, :payments)
                    .order(created_at: :desc)
                    .limit(100)

      if params[:date].present?
        date = Date.parse(params[:date]) rescue nil
        @orders = @orders.where("DATE(created_at) = ?", date) if date
      end

      if params[:status].present? && params[:status] != "all"
        @orders = @orders.where(status: params[:status])
      end
    end

    def new
      @shift = current_shift
      authorize Order, :create? if @shift
      load_tenant_menu!
      @cart = session[:barista_cart] || []
    end

    def create
      shift = current_shift
      unless shift
        redirect_to barista_new_order_path, alert: "Смена не открыта"
        return
      end

      authorize Order, :create?

      order = Barista::OrderCreationService.new(
        cart_items:     normalize_cart_items(params[:cart_items]),
        payment_method: params[:payment_method] || "cash",
        customer_name:  params[:customer_name].presence,
        promo_code:     params[:promo_code].presence,
        shift:          shift,
        tenant_id:      Current.tenant_id,
        user_id:        Current.user_id
      ).call!

      Barista::OrderBoardBroadcaster.call(order: order, old_status: "pending_payment")
      redirect_to barista_dashboard_path, notice: "Заказ ##{order.order_number} создан успешно"
    rescue Barista::CartValidationService::CartValidationError => e
      Rails.logger.warn("Cart validation failed: #{e.message}")
      redirect_to barista_new_order_path, alert: e.message
    rescue Barista::OrderCreationService::OrderCreationError => e
      Rails.logger.warn("Order creation rejected: #{e.message}")
      redirect_to barista_new_order_path, alert: e.message
    rescue => e
      Rails.logger.error("Order creation failed: #{e.class} — #{e.message}")
      redirect_to barista_new_order_path, alert: "Не удалось создать заказ. Попробуйте ещё раз."
    end

    def update_status
      return redirect_no_open_shift unless current_shift

      @order = shift_accessible_orders.find(params[:id])
      authorize @order, :update_status?

      begin
        result = Barista::OrderStatusUpdateService.new(
          order: @order,
          new_status: params[:status],
          user_id: Current.user_id,
          comment: params[:comment]
        ).call!

        @order = result[:order]
        @old_status = result[:old_status]
        Barista::OrderBoardBroadcaster.call(order: @order, old_status: result[:old_status])

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to barista_dashboard_path, notice: "Статус обновлён" }
        end
      rescue Barista::OrderStatusUpdateService::OrderStatusUpdateError => e
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: "barista/dashboard/order_card", locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: e.message }
        end
      end
    end

    def cancel
      return redirect_no_open_shift unless current_shift

      @order = shift_accessible_orders.find(params[:id])
      authorize @order, :cancel?

      unless @order.can_be_cancelled?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: "barista/dashboard/order_card", locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Заказ нельзя отменить" }
        end
        return
      end

      if params[:reason].to_s.strip.blank?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: "barista/dashboard/order_card", locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Укажите причину отмены" }
        end
        return
      end

      @old_status = @order.status

      Barista::OrderCancellationService.new(
        order: @order,
        actor: current_user,
        tenant_id: Current.tenant_id,
        user_id: Current.user_id,
        reason: params[:reason],
        reason_code: params[:reason_code],
        ingredients_used: params[:ingredients_used],
        request_id: request.request_id
      ).call!

      @order = @order.reload
      Barista::OrderBoardBroadcaster.call(order: @order, old_status: @old_status)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to barista_dashboard_path, notice: "Заказ отменён" }
      end
    rescue Barista::OrderCancellationService::OrderCancellationError => e
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: "barista/dashboard/order_card", locals: { order: @order }) }
        format.html { redirect_to barista_dashboard_path, alert: e.message }
      end
    end

    private

    def shift_accessible_orders
      BoardOrdersQuery.shift_accessible_scope(
        tenant_id: Current.tenant_id,
        cash_shift: current_shift
      )
    end

    def redirect_no_open_shift
      message = "Смена не открыта. Откройте смену перед работой с заказами."
      respond_to do |format|
        format.turbo_stream { redirect_to barista_dashboard_path, alert: message }
        format.html { redirect_to barista_dashboard_path, alert: message }
        format.json { render json: { error: message }, status: :forbidden }
      end
      nil
    end

    def broadcast_order_counts
      counts = Barista::BoardOrdersQuery.slot_counts(tenant_id: Current.tenant_id)
      stream = "orders_#{Current.tenant_id}"

      {
        "count-accepted" => counts[:accepted],
        "count-preparing" => counts[:preparing],
        "total-on-board" => counts[:total]
      }.each do |target, count|
        Turbo::StreamsChannel.broadcast_replace_to(stream, target: target, html: count.to_s)
      end
    end

    # HTML-форма шлёт cart_items[0][product_id]; интеграционные тесты — массив хэшей.
    def normalize_cart_items(raw)
      return [] if raw.blank?

      list = if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
               raw.values
      else
               Array(raw)
      end
      list.map { |item| item.is_a?(ActionController::Parameters) ? item.to_unsafe_h : item.to_h }
    end
  end
end
