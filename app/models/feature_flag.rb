class FeatureFlag < ApplicationRecord
  belongs_to :tenant
  belongs_to :enabled_by, class_name: 'User', optional: true

  validates :module, presence: true
  validates :tenant_id, uniqueness: { scope: :module }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
end
