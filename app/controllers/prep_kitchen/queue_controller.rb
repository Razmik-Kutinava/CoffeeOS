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

      @linked_sales_points = SalesPointRegistry.sales_points_for(Current.tenant_id)
      @orders = Queue::LinkedSalesPointOrdersQuery.call(
        prep_kitchen_tenant_id: Current.tenant_id,
        from: @from,
        to: @to,
        statuses: @statuses,
        user_id: Current.user_id
      )

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
