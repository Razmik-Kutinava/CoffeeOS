# frozen_string_literal: true

module BlogHelper
  def blog_cta_href
    ENV["BLOG_TELEGRAM_URL"].presence || "https://t.me/"
  end
end
