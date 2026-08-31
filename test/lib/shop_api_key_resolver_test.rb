# frozen_string_literal: true

require "test_helper"
require "shop_api_key_resolver"

class ShopApiKeyResolverTest < ActiveSupport::TestCase
  setup do
    @prev = ENV["SHOP_API_KEY"]
  end

  teardown do
    ENV["SHOP_API_KEY"] = @prev
  end

  test "resolve! returns ENV SHOP_API_KEY" do
    ENV["SHOP_API_KEY"] = "from-env-key"
    assert_equal "from-env-key", ShopApiKeyResolver.resolve!
  end

  test "resolve! uses fly_env when ENV blank" do
    ENV.delete("SHOP_API_KEY")
    assert_equal "from-fly", ShopApiKeyResolver.resolve!(fly_env: ->(_k) { "from-fly" })
  end

  test "resolve! raises when key missing" do
    ENV.delete("SHOP_API_KEY")
    assert_raises(RuntimeError) { ShopApiKeyResolver.resolve! }
  end
end
