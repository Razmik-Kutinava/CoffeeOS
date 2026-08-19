class SyncContactToCrmJob < ApplicationJob
  queue_as :default

  def perform(order_email_id)
    order_email = OrderEmail.find_by(id: order_email_id)
    return if order_email.blank?

    if !order_email.marketing_consent || order_email.status == "bounced"
      return
    end

    order = order_email.order
    return if order.blank?
    return if order_email.email.blank?

    begin
      sync_contact_to_crm(order, order_email)
    rescue => e
      Rails.logger.error("[SyncContactToCrmJob] Failed to sync contact for order_email #{order_email_id}: #{e.message}")
    end
  end

  private

  def sync_contact_to_crm(order, order_email)
    contact_data = {
      user_id: order.customer_id,
      order_id: order.id,
      email: order_email.email,
      marketing_consent: order_email.marketing_consent
    }

    # TODO: Integrate with actual CRM provider
    # For now, this is a placeholder that logs the sync attempt
    Rails.logger.info("[SyncContactToCrmJob] Syncing contact: #{contact_data}")
  end
end
