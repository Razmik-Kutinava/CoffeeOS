# frozen_string_literal: true

# Staff panels: wrap request in AR transaction so SET LOCAL app.current_* sticks (Shop API pattern).
module WithTenantPgContext
  extend ActiveSupport::Concern

  included do
    around_action :with_tenant_pg_transaction!
  end

  private

  def with_tenant_pg_transaction!
    ActiveRecord::Base.transaction { yield }
  end
end
