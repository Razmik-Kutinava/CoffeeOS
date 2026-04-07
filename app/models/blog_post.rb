# frozen_string_literal: true

class BlogPost < ApplicationRecord
  belongs_to :blog_category, optional: true

  # Виртуальное поле для формы: «опубликовать» (checkbox)
  attr_accessor :publish

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, on: :create
  before_save :sanitize_body_html
  before_save :sync_published_at_from_publish

  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  scope :recent_first, -> { order(published_at: :desc, created_at: :desc) }

  ALLOWED_TAGS       = %w[p br strong b em i u ul ol li blockquote a h2 h3].freeze
  ALLOWED_ATTRIBUTES = %w[href].freeze
  SANITIZER          = Rails::Html::SafeListSanitizer.new

  def published?
    published_at.present?
  end

  def to_param
    slug
  end

  def display_meta_title
    meta_title.presence || title
  end

  def display_meta_description
    meta_description.presence || intro.to_s.truncate(160)
  end

  private

  def sync_published_at_from_publish
    return if publish.nil?

    if ActiveModel::Type::Boolean.new.cast(publish)
      self.published_at ||= Time.current
    else
      self.published_at = nil
    end
  end

  def generate_slug
    return if slug.present?

    base = title.to_s.parameterize
    self.slug = base
    return if base.blank?

    suffix = 1
    while BlogPost.where.not(id: id).exists?(slug: slug)
      self.slug = "#{base}-#{suffix}"
      suffix += 1
    end
  end

  def sanitize_body_html
    return if body.blank?

    self.body = SANITIZER.sanitize(body, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end
end
