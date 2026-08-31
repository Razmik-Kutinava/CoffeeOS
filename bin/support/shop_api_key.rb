# frozen_string_literal: true

require_relative "../../lib/shop_api_key_resolver"

def resolve_shop_api_key(fly_env: nil)
  ShopApiKeyResolver.resolve!(fly_env: fly_env)
end
