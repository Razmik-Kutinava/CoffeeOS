module PrepKitchen
  class IncidentsController < BaseController
    def index
      @incidents = PrepKitchen::Incidents::Collector.call(tenant_id: Current.tenant_id, user_id: Current.user_id)
      @linked_sales_points = SalesPointRegistry.sales_points_for(Current.tenant_id)
    end
  end
end
