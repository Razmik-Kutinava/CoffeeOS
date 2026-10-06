class Session < ApplicationRecord
  belongs_to :user
  belongs_to :tenant, optional: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  # УК и владелец франшизы входят без точки — tenant_id у сессии может быть NULL.
  def ensure_tenant_id; end
end
