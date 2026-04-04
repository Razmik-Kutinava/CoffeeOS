class Order < ApplicationRecord
  enum :status, {
    pending_payment: 'pending_payment',
    accepted: 'accepted',
    preparing: 'preparing',
    ready: 'ready',
    issued: 'issued',
    closed: 'closed',
    cancelled: 'cancelled'
  }
  enum :source, { kiosk: 'kiosk', app: 'app', manual: 'manual', mobile: 'mobile' }

  belongs_to :tenant
  belongs_to :customer, class_name: 'MobileCustomer', foreign_key: 'customer_id', optional: true
  belongs_to :cash_shift, optional: true
  # cancel_reason_code - ссылка на order_cancel_reasons.code (без FK в Rails, только в БД)
  # cancel_stage - строка, не enum
  has_many :order_items, dependent: :destroy
  has_many :order_status_logs, dependent: :destroy
  has_many :payments, dependent: :destroy

  # `barista/orders#create` создаёт Order с пустым `order_number: ''`,
  # рассчитывая на заполнение на уровне БД (триггер). Чтобы Rails не
  # блокировал insert, разрешаем пустой номер для этого сценария.
  validates :order_number, presence: true, unless: -> {
    order_number.blank? && source.in?(%w[manual mobile])
  }
  validates :source, presence: true
  validates :status, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :discount_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :final_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :amounts_consistency

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :for_barista_board, ->(tenant_id) { where(tenant_id: tenant_id).where(status: %w[accepted preparing ready]) }
  scope :active, -> { where(status: ['accepted', 'preparing', 'ready']) }
  scope :recent, -> { order(created_at: :desc) }
  scope :mobile, -> { where(source: 'mobile') }
  scope :with_qr_token, -> { where.not(qr_token: nil) }
  scope :qr_valid, -> { where('qr_expires_at > ?', Time.current) }

  def qr_expired?
    qr_expires_at.present? && qr_expires_at <= Time.current
  end

  def qr_valid?
    qr_token.present? && !qr_expired?
  end

  def can_be_cancelled?
    !status.in?(%w[issued closed cancelled])
  end

  def can_change_status?
    case status
    when 'accepted'
      true
    when 'preparing'
      true
    when 'ready'
      true
    else
      false
    end
  end

  private

  def amounts_consistency
    return unless total_amount && discount_amount && final_amount
    return if final_amount == total_amount - discount_amount

    errors.add(:final_amount, 'должна равняться total_amount - discount_amount')
  end
end
