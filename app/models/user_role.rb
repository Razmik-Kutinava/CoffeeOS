class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :tenant, optional: true

  POINT_STAFF_ROLE_CODES = %w[
    barista shift_manager general_manager prep_kitchen_manager prep_kitchen_worker
  ].freeze

  validates :user_id, uniqueness: { scope: [ :role_id, :tenant_id ] }
  validate :tenant_required_for_point_staff_role

  private

  def tenant_required_for_point_staff_role
    return unless role

    code = role.code
    return unless POINT_STAFF_ROLE_CODES.include?(code)
    return if tenant_id.present?

    errors.add(:tenant_id, "обязателен для роли #{code}")
  end
end
