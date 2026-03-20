class FeatureFlagsLog < ApplicationRecord
  enum :action, { enabled: 'enabled', disabled: 'disabled' }

  belongs_to :tenant
  belongs_to :changed_by, class_name: 'User', optional: true

  validates :module, presence: true
  validates :action, presence: true
end
