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
        cart_items:     params[:cart_items] || [],
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

      new_status = params[:status]

      unless @order.can_change_status?
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("order_#{@order.id}", partial: 'barista/dashboard/order_card', locals: { order: @order }) }
          format.html { redirect_to barista_dashboard_path, alert: "Нельзя изменить статус" }
        end
        return
      end
      
      unless @order.can_transition_to?(new_status)
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

      # BUG-017 FIX: При отмене в статусе 'preparing' ингредиенты уже списаны триггером.
      # Если бариста подтвердил что ингредиенты НЕ использованы — создаём возвратное движение.
      if old_status == 'preparing' && params[:ingredients_used] == 'false'
        movement = StockMovement.create!(
          tenant_id: Current.tenant_id,
          movement_type: :return,
          status: :confirmed,
          created_by_id: Current.user_id,
          confirmed_by_id: Current.user_id,
          confirmed_at: Time.current,
          reference_id: @order.id,
          note: "Возврат при отмене заказа ##{@order.order_number} (ингредиенты не использованы)"
        )

        # FIX: Load all recipes at once to avoid N+1 queries
        product_ids = @order.order_items.pluck(:product_id)
        recipes = ProductRecipe.where(product_id: product_ids).includes(:ingredient)

        @order.order_items.each do |item|
          item_recipes = recipes.select { |r| r.product_id == item.product_id }
          item_recipes.each do |recipe|
            qty_to_restore = recipe.qty_per_serving * item.quantity
            StockMovementItem.create!(
              movement_id: movement.id,
              ingredient_id: recipe.ingredient_id,
              qty: qty_to_restore
            )
            IngredientTenantStock.where(tenant_id: Current.tenant_id, ingredient_id: recipe.ingredient_id)
                                 .update_all("qty = qty + #{qty_to_restore.to_f}")
          end
        end
      end
      
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
  end
end
