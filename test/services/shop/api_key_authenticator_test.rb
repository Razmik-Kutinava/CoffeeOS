# frozen_string_literal: true

require "test_helper"

class Shop::ApiKeyAuthenticatorTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant_a = create_tenant!(name: "Point A", slug: "auth-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(name: "Point B", slug: "auth-b-#{SecureRandom.hex(3)}")
    @raw_a = "sk_test_tenant_a_#{SecureRandom.hex(8)}"
    @raw_prev = "sk_test_tenant_a_prev_#{SecureRandom.hex(8)}"
    @old_env = ENV["SHOP_API_KEY"]
    @old_fallback = ENV["SHOP_API_KEY_FALLBACK"]
    ENV.delete("SHOP_API_KEY")
    ENV.delete("SHOP_API_KEY_FALLBACK")

    @key_a = ShopApiKey.create!(
      tenant_id: @tenant_a.id,
      name: "mcp-a",
      token_digest: ShopApiKey.digest(@raw_a),
      token_prefix: @raw_a[0, 8],
      active: true,
      global_ops: false
    )
    @key_prev = ShopApiKey.create!(
      tenant_id: @tenant_a.id,
      name: "mcp-a-prev",
      token_digest: ShopApiKey.digest(@raw_prev),
      token_prefix: @raw_prev[0, 8],
      active: true,
      global_ops: false
    )
  end

  teardown do
    ENV["SHOP_API_KEY"] = @old_env
    ENV["SHOP_API_KEY_FALLBACK"] = @old_fallback
    Current.tenant_id = nil
  end

  test "valid key matches same tenant" do
    result = Shop::ApiKeyAuthenticator.call!(raw_key: @raw_a, tenant_id: @tenant_a.id)
    assert result
  end

  test "valid key rejected for other tenant" do
    assert_raises(Shop::ApiKeyAuthenticator::Unauthorized) do
      Shop::ApiKeyAuthenticator.call!(raw_key: @raw_a, tenant_id: @tenant_b.id)
    end
  end

  test "wrong key raises unauthorized" do
    assert_raises(Shop::ApiKeyAuthenticator::Unauthorized) do
      Shop::ApiKeyAuthenticator.call!(raw_key: "sk_wrong", tenant_id: @tenant_a.id)
    end
  end

  test "revoked key raises unauthorized" do
    @key_a.update!(revoked_at: Time.current)
    assert_raises(Shop::ApiKeyAuthenticator::Unauthorized) do
      Shop::ApiKeyAuthenticator.call!(raw_key: @raw_a, tenant_id: @tenant_a.id)
    end
  end

  test "expired key raises unauthorized" do
    @key_a.update!(expires_at: 1.hour.ago)
    assert_raises(Shop::ApiKeyAuthenticator::Unauthorized) do
      Shop::ApiKeyAuthenticator.call!(raw_key: @raw_a, tenant_id: @tenant_a.id)
    end
  end

  test "inactive key raises unauthorized" do
    @key_a.update!(active: false)
    assert_raises(Shop::ApiKeyAuthenticator::Unauthorized) do
      Shop::ApiKeyAuthenticator.call!(raw_key: @raw_a, tenant_id: @tenant_a.id)
    end
  end

  test "previous active key still accepted until revoke" do
    result = Shop::ApiKeyAuthenticator.call!(raw_key: @raw_prev, tenant_id: @tenant_a.id)
    assert result
  end

  test "global_ops key allows any tenant" do
    raw = "sk_global_ops_#{SecureRandom.hex(8)}"
    ShopApiKey.create!(
      tenant_id: nil,
      name: "ops",
      token_digest: ShopApiKey.digest(raw),
      token_prefix: raw[0, 8],
      active: true,
      global_ops: true
    )
    assert Shop::ApiKeyAuthenticator.call!(raw_key: raw, tenant_id: @tenant_b.id)
  end
end
