module PrepKitchen
  module Stock
    class MovementCanceller
      def self.call(movement:)
        new(movement: movement).call
      end

      def initialize(movement:)
        @movement = movement
      end

      def call
        return PrepKitchen::Result.failure("Можно отменить только черновик") unless @movement.status == "draft"

        @movement.update!(status: "cancelled")
        PrepKitchen::Result.success(@movement)
      rescue StandardError => e
        PrepKitchen::Result.failure(e.message)
      end
    end
  end
end
