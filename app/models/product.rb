class Product < ApplicationRecord
  belongs_to :category
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :copied_from, class_name: 'Product', optional: true
  has_many :copies, class_name: 'Product', foreign_key: 'copied_from_id', dependent: :nullify
  has_many :product_modifier_groups, dependent: :destroy
  has_many :product_recipes, dependent: :destroy
  has_many :product_tenant_settings, dependent: :destroy
  has_many :product_menu_visibilities, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc) }
end
