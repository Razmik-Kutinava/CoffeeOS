# frozen_string_literal: true

module Shop
  module ApiKeys
    # Issue a shop API key: prints raw once to stdout; DB stores digest only.
    class Issue
      def self.call!(tenant_id: nil, name:, global_ops: false)
        new(tenant_id: tenant_id, name: name, global_ops: global_ops).call!
      end

      def initialize(tenant_id:, name:, global_ops: false)
        @tenant_id = tenant_id
        @name = name.to_s
        @global_ops = global_ops
      end

      def call!
        raw = ShopApiKey.generate_raw_token
        record = Rls::GucContext.with_shop_api_key_lookup do
          ShopApiKey.create!(
            tenant_id: @global_ops ? nil : @tenant_id,
            name: @name.presence || "unnamed",
            token_digest: ShopApiKey.digest(raw),
            token_prefix: raw[0, 8],
            active: true,
            global_ops: @global_ops
          )
        end
        { record: record, raw_token: raw }
      end
    end
  end
end
