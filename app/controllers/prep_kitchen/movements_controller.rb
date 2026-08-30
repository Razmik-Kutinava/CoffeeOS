module PrepKitchen
  class MovementsController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize StockMovement, :index?
      @status = sanitize_status(params[:status])
      @movement_type = sanitize_type(params[:movement_type])

      @movements = StockMovement.for_current_tenant.includes(:created_by, :confirmed_by, stock_movement_items: :ingredient)
      @movements = @movements.where(status: @status) if @status != "all"
      @movements = @movements.where(movement_type: @movement_type) if @movement_type != "all"
      @movements = @movements.recent.limit(200)
    end

    def new
      authorize StockMovement, :create?
      @movement = StockMovement.new
      @ingredients = Ingredient.active.order(:name).limit(500)
    end

    def create
      authorize StockMovement, :create?

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
      authorize StockMovement, :confirm?
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
      authorize StockMovement, :cancel?
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
      raw = params.require(:movement)
      permitted = raw.permit(:movement_type, :note)
      permitted[:items] = normalize_items(raw[:items])
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

    def normalize_items(items)
      return [] if items.blank?

      values = items.is_a?(Hash) ? items.values : Array(items)
      values.filter_map do |row|
        h = row.respond_to?(:permit) ? row.permit(:ingredient_id, :qty_change, :unit_cost).to_h : row.to_h
        h = h.with_indifferent_access
        next if h[:ingredient_id].blank? || h[:qty_change].blank?

        h.slice(:ingredient_id, :qty_change, :unit_cost)
      end
    end
  end
end
