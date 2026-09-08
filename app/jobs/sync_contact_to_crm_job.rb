# frozen_string_literal: true

class SyncContactToCrmJob < ApplicationJob
  queue_as :default

  # Transient Brevo/network failures → Solid Queue auto-retry (raise alone is not enough).
  retry_on Shop::CrmContactSync::Error, wait: :polynomially_longer, attempts: 5
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(order_email_id)
    order_email = OrderEmail.find_by(id: order_email_id)
    return if order_email.blank?

    if !order_email.marketing_consent || order_email.status == "bounced"
      return
    end

    order = order_email.order
    return if order.blank?
    return if order_email.email.blank?

    Shop::CrmContactSync.call!(order: order, order_email: order_email)
  rescue Shop::CrmContactSync::Error => e
    Rails.logger.error("[SyncContactToCrmJob] CRM sync failed for order_email #{order_email_id}: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("[SyncContactToCrmJob] Failed to sync contact for order_email #{order_email_id}: #{e.message}")
    raise
  end
end
