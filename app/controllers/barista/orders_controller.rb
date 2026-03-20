module Barista
  class OrdersController < BaseController
    def show
      @order = Order.for_current_tenant.find(params[:id])
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
                unit_price: item.unit_price,
                total_price: item.total_price
              }
            end
          }
        end
      end
    end
    
    def history
      @orders = Order.for_current_tenant
                    .where(status: ['closed', 'cancelled', 'issued'])
                    .includes(:order_items, :payments)
                    .order(created_at: :desc)
                    .limit(100)
      
      if params[:date].present?
        date = Date.parse(params[:date])
        @orders = @orders.where("DATE(created_at) = ?", date)
      end
      
      if params[:status].present? && params[:status] != 'all'
        @orders = @orders.where(status: params[:status])
      end
    end
    
    def new
      @products = Product.joins(:product_tenant_settings)
                         .where(product_tenant_settings: { tenant_id: Current.tenant_id, is_enabled: true })
                         .includes(:category, :product_tenant_settings)
                         .order('categories.sort_order ASC, products.sort_order ASC')
      @categories = Category.active.order(sort_order: :asc)
      @cart = session[:barista_cart] || []
    end
    
    def create
      cart_items = params[:cart_items] || []
      payment_method = params[:payment_method] || 'cash'
      customer_name = params[:customer_name].presence
      promo_code = params[:promo_code].presence
      
      if cart_items.empty?
        redirect_to barista_new_order_path, alert: "Корзина пуста"
        return
      end
      
      shift = current_shift
      unless shift
        redirect_to barista_new_order_path, alert: "Смена не открыта"
        return
      end
      
      ActiveRecord::Base.transaction do
        # Подсчитываем суммы
        total_amount = 0
        order_items_data = []
        
        cart_items.each do |item|
          product_id = item[:product_id] || item['product_id']
          quantity = (item[:quantity] || item['quantity'] || 1).to_i
          
          product = Product.find(product_id)
          setting = product.product_tenant_settings.find_by(tenant_id: Current.tenant_id)
          
          unless setting&.is_enabled && !setting.is_sold_out
            raise "Продукт #{product.name} недоступен"
          end
          
          item_price = setting.price
          item_total = item_price * quantity
          total_amount += item_total
          
          order_items_data << {
            product: product,
            quantity: quantity,
            price: item_price,
            total_price: item_total
          }
        end
        
        # Применяем промокод если есть (пока без валидации, просто заглушка)
        discount_amount = 0
        promo_code_id = nil
        if promo_code.present?
          # TODO: валидация промокода через модель PromoCode когда будет создана
          discount_amount = (total_amount * 0.1).round(2) # 10% скидка для теста
        end
        
        final_amount = total_amount - discount_amount
        
        # Создаём заказ (order_number сгенерируется триггером)
        order = Order.create!(
          tenant_id: Current.tenant_id,
          cash_shift_id: shift.id,
          order_number: '', # Триггер сгенерирует автоматически
          source: 'manual',
          customer_name: customer_name,
          status: 'accepted', # Сразу в статус accepted после оплаты
          total_amount: total_amount,
          discount_amount: discount_amount,
          final_amount: final_amount,
          promo_code_id: promo_code_id
        )
        
        # Создаём позиции заказа
        order_items_data.each do |item_data|
          OrderItem.create!(
            order_id: order.id,
            product_id: item_data[:product].id,
            product_name: item_data[:product].name,
            quantity: item_data[:quantity],
            unit_price: item_data[:price],
            total_price: item_data[:total_price]
          )
        end
        
        # Создаём платёж
        Payment.create!(
          order_id: order.id,
          tenant_id: Current.tenant_id,
          amount: final_amount,
          method: payment_method,
          provider: 'manual',
          status: 'succeeded',
          paid_at: Time.current
        )
        
        # Логируем статус
        OrderStatusLog.create!(
          order_id: order.id,
          status_from: 'pending_payment',
          status_to: 'accepted',
          changed_by_id: Current.user_id,
          source: 'barista',
          comment: 'Заказ создан баристой'
        )
        
        # Broadcast через Action Cable
        broadcast_order_update(order, 'pending_payment')
        
        redirect_to barista_dashboard_path, notice: "Заказ ##{order.order_number} создан успешно"
      end
    rescue => e
      Rails.logger.error("Order creation failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      redirect_to barista_new_order_path, alert: "Ошибка создания заказа: #{e.message}"
    end
    
    def update_status
      @order = Order.for_current_tenant.find(params[:id])
      
      new_status = params[:status]
      
      unless @order.can_change_status?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Нельзя изменить статус" }
        end
        return
      end
      
      # Валидация перехода статуса
      valid_transitions = {
        'accepted' => ['preparing', 'cancelled'],
        'preparing' => ['ready', 'cancelled'],
        'ready' => ['issued', 'cancelled']
      }
      
      unless valid_transitions[@order.status]&.include?(new_status)
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Недопустимый переход статуса" }
        end
        return
      end
      
      old_status = @order.status
      @order.update!(status: new_status)
      
      # Логирование изменения статуса
      OrderStatusLog.create!(
        order_id: @order.id,
        status_from: old_status,
        status_to: new_status,
        changed_by_id: Current.user_id,
        device_id: nil,
        source: 'barista',
        comment: params[:comment]
      )
      
      # Broadcast через Action Cable
      broadcast_order_update(@order, old_status)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to barista_dashboard_path, notice: "Статус обновлён" }
      end
    end
    
    def cancel
      @order = Order.for_current_tenant.find(params[:id])
      
      unless @order.can_be_cancelled?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Заказ нельзя отменить" }
        end
        return
      end
      
      old_status = @order.status
      @order.update!(
        status: 'cancelled',
        cancel_reason: params[:reason] || 'Отменено баристой',
        cancel_reason_code: params[:reason_code],
        cancel_stage: old_status
      )
      
      # Логирование отмены
      OrderStatusLog.create!(
        order_id: @order.id,
        status_from: old_status,
        status_to: 'cancelled',
        changed_by_id: Current.user_id,
        device_id: nil,
        source: 'barista',
        comment: params[:reason] || 'Отменено баристой'
      )
      
      # Broadcast через Action Cable - удаляем из табло
      Turbo::StreamsChannel.broadcast_remove_to(
        "orders_#{Current.tenant_id}",
        target: "order_#{@order.id}"
      )
      
      # Обновление счётчиков
      counts = {
        new: Order.for_barista_board(Current.tenant_id).where(status: 'accepted').count,
        preparing: Order.for_barista_board(Current.tenant_id).where(status: 'preparing').count,
        ready: Order.for_barista_board(Current.tenant_id).where(status: 'ready').count
      }
      
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

      # TV board: перерисовываем колонки целиком для корректного idx.
      broadcast_tv_columns_update
      
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("order_#{@order.id}") }
        format.html { redirect_to barista_dashboard_path, notice: "Заказ отменён" }
      end
    end
    
    private

    def tv_board_setting_for_current_tenant
      TvBoardSetting.find_by(tenant_id: Current.tenant_id) ||
        TvBoardSetting.create!(
          tenant_id: Current.tenant_id,
          show_order_count: 10,
          display_seconds_ready: 60,
          theme: 'dark'
        )
    end

    def orders_for_tv_column(status, limit)
      Order.for_barista_board(Current.tenant_id)
           .where(status: status)
           .order(created_at: :asc)
           .limit(limit)
    end

    def broadcast_tv_columns_update
      tv_setting = tv_board_setting_for_current_tenant

      Device.for_current_tenant.where(device_type: "tv_board", is_active: true).find_each do |device|
        effective = device.tv_effective_show_order_count(tv_setting)
        stream = "tv_orders_#{device.id}"

        Turbo::StreamsChannel.broadcast_replace_to(
          stream,
          target: "tv-ads-area",
          partial: "tv_board/ads_area",
          locals: { tv_setting: tv_setting, effective_limit: effective }
        )

        accepted_orders = effective > 0 ? orders_for_tv_column("accepted", effective) : Order.none
        preparing_orders = effective > 0 ? orders_for_tv_column("preparing", effective) : Order.none
        ready_orders = effective > 0 ? orders_for_tv_column("ready", effective) : Order.none

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
      
      # Обновление счётчиков
      counts = {
        new: Order.for_barista_board(Current.tenant_id).where(status: 'accepted').count,
        preparing: Order.for_barista_board(Current.tenant_id).where(status: 'preparing').count,
        ready: Order.for_barista_board(Current.tenant_id).where(status: 'ready').count
      }
      
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

      # TV board: перерисовываем колонки целиком для корректного idx.
      broadcast_tv_columns_update
    end
  end
end
