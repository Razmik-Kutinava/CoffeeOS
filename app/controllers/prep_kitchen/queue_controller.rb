module PrepKitchen
  class QueueController < BaseController
    def index
      @from = parsed_time(params[:from]) || 2.hours.ago
      @to = parsed_time(params[:to]) || 6.hours.from_now
      @statuses = normalize_statuses(params[:status])

      if @from > @to || (@to - @from) > 7.days
        redirect_to prep_kitchen_queue_path, alert: "Некорректный диапазон дат"
        return
      end

      @orders = Order.for_current_tenant
                     .where(status: @statuses)
                     .where(created_at: @from..@to)
                     .includes(:order_items)
                     .order(created_at: :asc)
                     .limit(200)

      @demand_result = PrepKitchen::Queue::DemandCalculator.call(orders: @orders)
    end

    private

    def parsed_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def normalize_statuses(raw_statuses)
      allowed = %w[accepted preparing]
      statuses = Array(raw_statuses).presence || allowed
      statuses.select { |status| allowed.include?(status) }.presence || allowed
    end
  end
end
