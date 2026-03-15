class MenuType < ApplicationRecord
  has_many :product_menu_visibilities, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
