class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :tenant, optional: true

  validates :user_id, uniqueness: { scope: [:role_id, :tenant_id] }
end
