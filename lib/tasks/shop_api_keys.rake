# frozen_string_literal: true

namespace :shop do
  namespace :api_keys do
    desc "Issue shop API key. Args: tenant_id,name  OR global_ops,name (prints raw once)"
    task :issue, [ :tenant_id_or_flag, :name ] => :environment do |_t, args|
      flag = args[:tenant_id_or_flag].to_s
      name = args[:name].presence || "issued"
      if flag == "global_ops"
        result = Shop::ApiKeys::Issue.call!(tenant_id: nil, name: name, global_ops: true)
      else
        abort "Usage: rails shop:api_keys:issue[<tenant_uuid>,name]" if flag.blank?
        result = Shop::ApiKeys::Issue.call!(tenant_id: flag, name: name, global_ops: false)
      end
      record = result[:record]
      puts "id=#{record.id} tenant_id=#{record.tenant_id} global_ops=#{record.global_ops} prefix=#{record.token_prefix}"
      puts "RAW_KEY (save once, not stored): #{result[:raw_token]}"
    end
  end
end
