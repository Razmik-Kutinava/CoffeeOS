module PrepKitchen
  module Stock
    class MovementConfirmer
      def self.call(movement:, user:)
        new(movement: movement, user: user).call
      end

      def initialize(movement:, user:)
        @movement = movement
        @user = user
      end

      def call
        return PrepKitchen::Result.failure("Можно подтвердить только черновик") unless @movement.status == "draft"

        ActiveRecord::Base.transaction do
          @movement.stock_movement_items.each do |item|
            stock = IngredientTenantStock.lock.find_or_create_by!(
              tenant_id: @movement.tenant_id,
              ingredient_id: item.ingredient_id
            ) do |new_stock|
              new_stock.qty = 0
              new_stock.min_qty = 0
            end

            new_qty = stock.qty + item.qty_change
            if new_qty.negative?
              raise ActiveRecord::Rollback, "Остаток не может быть отрицательным"
            end

            stock.update!(qty: new_qty, last_updated_at: Time.current)
          end

          @movement.update!(status: "confirmed", confirmed_by: @user, confirmed_at: Time.current)
        end

        return PrepKitchen::Result.failure("Остаток не может быть отрицательным") unless @movement.reload.status == "confirmed"

        PrepKitchen::Result.success(@movement)
      rescue StandardError => e
        PrepKitchen::Result.failure(e.message)
      end
    end
  end
end
