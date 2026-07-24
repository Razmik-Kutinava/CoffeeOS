# frozen_string_literal: true

# Персистентная cookie сессии для PWA (не session-only).
Rails.application.config.session_store :cookie_store,
  key: "_coffeeos_session",
  expire_after: 90.days,
  same_site: :lax
