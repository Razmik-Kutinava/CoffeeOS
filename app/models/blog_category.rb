# frozen_string_literal: true

class BlogCategory < ApplicationRecord
  has_many :blog_posts, dependent: :nullify

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, on: :create

  scope :ordered, -> { order(:sort_order, :name) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize if slug.blank? && name.present?
  end
end
