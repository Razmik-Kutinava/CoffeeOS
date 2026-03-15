class MobileSession < ApplicationRecord
  belongs_to :customer, class_name: 'MobileCustomer', foreign_key: 'customer_id'

  validates :refresh_token, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def active?
    is_active && expires_at > Time.current
  end

  def deactivate!
    update!(is_active: false)
  end

  def update_last_used!
    update!(last_used_at: Time.current)
  end
end
