class Category < ApplicationRecord
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc) }
end
