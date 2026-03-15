class TvBoardSetting < ApplicationRecord
  belongs_to :tenant
  belongs_to :updated_by, class_name: 'User', optional: true

  validates :tenant_id, uniqueness: true
  validates :show_order_count, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :display_seconds_ready, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 300 }
  validates :theme, inclusion: { in: %w[dark light brand] }
end
