# frozen_string_literal: true

# IB-D-03 / V2-SEC-07: server-side shop API key for curl/MCP (not from browser meta).
module ShopApiKeyResolver
  module_function

  def resolve!(fly_env: nil)
    key = ENV["SHOP_API_KEY"].to_s.strip
    return key if key.present?

    if fly_env.respond_to?(:call)
      key = fly_env.call("SHOP_API_KEY").to_s.strip
      return key if key.present?
    end

    raise "SHOP_API_KEY not set — export ENV or provide fly_env (fly secrets / printenv)"
  end
end
