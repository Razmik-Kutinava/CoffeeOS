# frozen_string_literal: true

require "test_helper"

# Шаг 1: персистентная cookie сессии для PWA (90 дней).
class Shop::Api::SessionStoreConfigTest < ActiveSupport::TestCase
  test "session cookie key is _coffeeos_session with 90 day TTL and same_site lax" do
    opts = Rails.application.config.session_options
    assert_equal "_coffeeos_session", opts[:key]
    assert_equal 90.days, opts[:expire_after]
    assert_equal :lax, opts[:same_site]
  end
end
