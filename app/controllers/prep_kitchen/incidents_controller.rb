module PrepKitchen
  class IncidentsController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize :prep_kitchen_incident, :index?, policy_class: PrepKitchen::IncidentPolicy
      @incidents = PrepKitchen::Incidents::Collector.call(tenant_id: Current.tenant_id, user_id: Current.user_id)
      @linked_sales_points = SalesPointRegistry.sales_points_for(Current.tenant_id)
    end
  end
end
