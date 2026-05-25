module Barista
  class OrdersController < BaseController
    def show
      @order = Order.for_current_tenant.includes(:payments).find(params[:id])
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
            payment_status: @order.payments.first&.status || 'not_paid',
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
                    .where(status: ['closed', 'cancelled', 'issued'])
                    .includes(:order_items, :payments)
                    .order(created_at: :desc)
                    .limit(100)
      
      if params[:date].present?
        date = Date.parse(params[:date]) rescue nil
        @orders = @orders.where("DATE(created_at) = ?", date) if date
      end
      
      if params[:status].present? && params[:status] != 'all'
        @orders = @orders.where(status: params[:status])
      end
    end
    
    def new
      authorize Order, :create?
      @shift = current_shift
      @products = Product.joins(:product_tenant_settings)
                         .where(product_tenant_settings: { tenant_id: Current.tenant_id, is_enabled: true })
                         .includes(:category, :product_tenant_settings)
                         .order('categories.sort_order ASC, products.sort_order ASC')
      @categories = Category.active.order(sort_order: :asc)
      @cart = session[:barista_cart] || []
    end
    
    def create
      authorize Order, :create?

      shift = current_shift
      unless shift
        redirect_to barista_new_order_path, alert: "Смена не открыта"
        return
      end

      order = Barista::OrderCreationService.new(
        cart_items:     normalize_cart_items(params[:cart_items]),
        payment_method: params[:payment_method] || "cash",
        customer_name:  params[:customer_name].presence,
        promo_code:     params[:promo_code].presence,
        shift:          shift,
        tenant_id:      Current.tenant_id,
        user_id:        Current.user_id
      ).call!

      broadcast_order_update(order, "pending_payment")
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
      @order = Order.for_current_tenant.find(params[:id])
      authorize @order, :update_status?

      # BUG-005 FIX: Нельзя менять статус заказа без открытой кассовой смены.
      unless current_shift
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Смена не открыта. Откройте смену перед работой с заказами." }
        end
        return
      end

      begin
        result = Barista::OrderStatusUpdateService.new(
          order: @order,
          new_status: params[:status],
          user_id: Current.user_id,
          comment: params[:comment]
        ).call!

        @order = result[:order]
        broadcast_order_update(@order, result[:old_status])

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to barista_dashboard_path, notice: "Статус обновлён" }
        end
      rescue Barista::OrderStatusUpdateService::OrderStatusUpdateError => e
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: e.message }
        end
      end
    end
    
    def cancel
      @order = Order.for_current_tenant.find(params[:id])
      authorize @order, :cancel?

      # BUG-005 FIX: Нельзя отменять заказ без открытой кассовой смены.
      unless current_shift
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Смена не открыта. Откройте смену перед работой с заказами." }
        end
        return
      end

      unless @order.can_be_cancelled?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Заказ нельзя отменить" }
        end
        return
      end

      if params[:reason].to_s.strip.blank?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Укажите причину отмены" }
        end
        return
      end

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

      # Broadcast через Action Cable - удаляем из табло
      Turbo::StreamsChannel.broadcast_remove_to(
        "orders_#{Current.tenant_id}",
        target: "order_#{@order.id}"
      )
      
      # Обновление счётчиков — один запрос вместо трёх
      broadcast_order_counts

      # TV board: перерисовываем колонки целиком для корректного idx.
      BroadcastTvColumnsJob.perform_later(Current.tenant_id)

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("order_#{@order.id}") }
        format.html { redirect_to barista_dashboard_path, notice: "Заказ отменён" }
      end
    rescue Barista::OrderCancellationService::OrderCancellationError => e
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
        format.html { redirect_to barista_dashboard_path, alert: e.message }
      end
    end

    private

    def broadcast_order_counts
      raw = Order.for_barista_board(Current.tenant_id)
                 .where(status: %w[accepted preparing ready])
                 .group(:status)
                 .count
      counts = { new: raw['accepted'].to_i, preparing: raw['preparing'].to_i, ready: raw['ready'].to_i }

      Turbo::StreamsChannel.broadcast_replace_to(
        "orders_#{Current.tenant_id}",
        target: "count-new",
        partial: 'barista/dashboard/count_badge',
        locals: { count: counts[:new], type: 'new' }
      )
      Turbo::StreamsChannel.broadcast_replace_to(
        "orders_#{Current.tenant_id}",
        target: "count-preparing",
        partial: 'barista/dashboard/count_badge',
        locals: { count: counts[:preparing], type: 'preparing' }
      )
      Turbo::StreamsChannel.broadcast_replace_to(
        "orders_#{Current.tenant_id}",
        target: "count-ready",
        partial: 'barista/dashboard/count_badge',
        locals: { count: counts[:ready], type: 'ready' }
      )
    end

    def broadcast_order_update(order, old_status = nil)
      # Определяем в какую колонку переместить заказ
      target_column = case order.status
      when 'accepted'
        'orders-new'
      when 'preparing'
        'orders-preparing'
      when 'ready'
        'orders-ready'
      else
        nil
      end
      
      # Определяем из какой колонки удалить (старый статус)
      old_status ||= order.order_status_logs.order(created_at: :desc).second&.status_to || 'accepted'
      source_column = case old_status
      when 'accepted'
        'orders-new'
      when 'preparing'
        'orders-preparing'
      when 'ready'
        'orders-ready'
      else
        nil
      end
      
      # Удаляем из старой колонки если статус изменился
      if source_column && source_column != target_column
        Turbo::StreamsChannel.broadcast_remove_to(
          "orders_#{Current.tenant_id}",
          target: "order_#{order.id}"
        )
      end
      
      # Добавляем в новую колонку (или обновляем если остался в той же)
      if target_column
        if source_column == target_column
          # Обновляем карточку в той же колонке
          Turbo::StreamsChannel.broadcast_replace_to(
            "orders_#{Current.tenant_id}",
            target: "order_#{order.id}",
            partial: 'barista/dashboard/order_card',
            locals: { order: order }
          )
        else
          # Добавляем в новую колонку
          Turbo::StreamsChannel.broadcast_append_to(
            "orders_#{Current.tenant_id}",
            target: target_column,
            partial: 'barista/dashboard/order_card',
            locals: { order: order }
          )
        end
      end
      
      # Обновление счётчиков — один запрос вместо трёх
      broadcast_order_counts

      # TV board: перерисовываем колонки целиком для корректного idx.
      BroadcastTvColumnsJob.perform_later(Current.tenant_id)
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
