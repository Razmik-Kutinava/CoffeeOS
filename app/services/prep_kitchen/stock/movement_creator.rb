module PrepKitchen
  module Stock
    class MovementCreator
      MOVEMENT_TYPES = %w[receipt write_off inventory order_deduct return].freeze

      def self.call(tenant_id:, user:, params:)
        new(tenant_id: tenant_id, user: user, params: params).call
      end

      def initialize(tenant_id:, user:, params:)
        @tenant_id = tenant_id
        @user = user
        @params = params
      end

      def call
        payload = @params.with_indifferent_access
        movement_type = payload[:movement_type].to_s
        raw_items = payload[:items]
        normalized_items = raw_items.is_a?(Hash) ? raw_items.values : Array(raw_items)
        items = normalized_items.map { |item| item.with_indifferent_access }.reject { |item| item[:ingredient_id].blank? || item[:qty_change].blank? }

        return PrepKitchen::Result.failure("Неверный тип движения") unless MOVEMENT_TYPES.include?(movement_type)
        return PrepKitchen::Result.failure("Добавьте хотя бы одну позицию") if items.empty?

        ingredient_ids = items.map { |item| item[:ingredient_id] }
        return PrepKitchen::Result.failure("Ингредиенты в документе не должны повторяться") if ingredient_ids.uniq.size != ingredient_ids.size

        movement = nil

        ActiveRecord::Base.transaction do
          movement = StockMovement.create!(
            tenant_id: @tenant_id,
            movement_type: movement_type,
            status: "draft",
            note: payload[:note],
            created_by: @user
          )

          items.each do |item|
            movement.stock_movement_items.create!(
              ingredient_id: item[:ingredient_id],
              qty_change: item[:qty_change],
              unit_cost: item[:unit_cost]
            )
          end
        end

        PrepKitchen::Result.success(movement.reload)
      rescue ActiveRecord::RecordInvalid => e
        PrepKitchen::Result.failure(e.record.errors.full_messages.join(", "))
      rescue ActiveRecord::RecordNotSaved => e
        PrepKitchen::Result.failure(e.record&.errors&.full_messages&.join(", ") || e.message)
      end
    end
  end
end
