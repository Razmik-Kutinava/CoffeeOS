module PrepKitchen
  class IncidentsController < BaseController
    def index
      @incidents = PrepKitchen::Incidents::Collector.call(tenant_id: Current.tenant_id)
    end
  end
end
