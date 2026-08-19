class OrderEmail < ApplicationRecord
  enum :status, {
    pending: "pending",
    sent: "sent",
    bounced: "bounced",
    failed: "failed"
  }, prefix: true

  belongs_to :order
  has_one :tenant, through: :order

  validates :order_id, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
  validates :marketing_consent, inclusion: { in: [true, false] }

  validates :order_id, uniqueness: { scope: :email, message: "email must be unique per order" }

  after_create :enqueue_send_receipt_and_crm_jobs

  private

  def enqueue_send_receipt_and_crm_jobs
    SendOrderReceiptEmailJob.perform_later(id)
    SyncContactToCrmJob.perform_later(id) if marketing_consent
  end
end
