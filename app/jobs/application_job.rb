# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  # Defense-in-depth: after loading an order-scoped record, set Current + tenant GUC
  # from the record (Solid Queue is trusted; forged args still cannot "work as" another tenant).
  def with_order_tenant!(order, &block)
    Rls::JobTenantContext.with(order, &block)
  end

  def with_job_tenant_id!(tenant_id, &block)
    Rls::JobTenantContext.with_tenant_id(tenant_id, &block)
  end
end
