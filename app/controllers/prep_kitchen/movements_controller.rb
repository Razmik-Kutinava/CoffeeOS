module PrepKitchen
  class MovementsController < BaseController
    def index
      @status = sanitize_status(params[:status])
      @movement_type = sanitize_type(params[:movement_type])

      @movements = StockMovement.for_current_tenant.includes(:created_by, :confirmed_by, stock_movement_items: :ingredient)
      @movements = @movements.where(status: @status) if @status != "all"
      @movements = @movements.where(movement_type: @movement_type) if @movement_type != "all"
      @movements = @movements.recent.limit(200)
    end

    def new
      return no_rights unless prep_kitchen_manager?

      @movement = StockMovement.new
      @ingredients = Ingredient.active.order(:name).limit(500)
    end

    def create
      return no_rights unless prep_kitchen_manager?

      result = PrepKitchen::Stock::MovementCreator.call(
        tenant_id: Current.tenant_id,
        user: current_user,
        params: movement_params.to_h
      )
      if result.success?
        redirect_to prep_kitchen_movements_path, notice: "Черновик движения создан"
      else
        @movement = StockMovement.new
        @ingredients = Ingredient.active.order(:name).limit(500)
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def confirm
      return no_rights unless prep_kitchen_manager?

      movement = StockMovement.for_current_tenant.find(params[:id])
      result = PrepKitchen::Stock::MovementConfirmer.call(movement: movement, user: current_user)

      if result.success?
        redirect_to prep_kitchen_movements_path, notice: "Движение подтверждено"
      else
        redirect_to prep_kitchen_movements_path, alert: result.error
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to prep_kitchen_movements_path, alert: "Документ не найден"
    end

    def cancel
      return no_rights unless prep_kitchen_manager?

      movement = StockMovement.for_current_tenant.find(params[:id])
      result = PrepKitchen::Stock::MovementCanceller.call(movement: movement)
      if result.success?
        redirect_to prep_kitchen_movements_path, notice: "Движение отменено"
      else
        redirect_to prep_kitchen_movements_path, alert: result.error
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to prep_kitchen_movements_path, alert: "Документ не найден"
    end

    private

    def movement_params
      permitted = params.require(:movement).permit(:movement_type, :note)
      permitted[:items] = normalize_items(params.dig(:movement, :items))
      permitted
    end

    def sanitize_status(value)
      allowed = %w[all draft confirmed cancelled]
      allowed.include?(value) ? value : "all"
    end

    def sanitize_type(value)
      allowed = %w[all receipt write_off inventory order_deduct return]
      allowed.include?(value) ? value : "all"
    end

    def no_rights
      redirect_to prep_kitchen_movements_path, alert: "Недостаточно прав"
    end

    def normalize_items(items)
      return [] if items.blank?

      values = items.is_a?(Hash) ? items.values : Array(items)
      values.map { |row| row.respond_to?(:permit) ? row.permit(:ingredient_id, :qty_change, :unit_cost).to_h : row }
    end
  end
end
