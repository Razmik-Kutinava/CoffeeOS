#!/usr/bin/env ruby
# frozen_string_literal: true

# Fly: create sales_point via Provision → verify key → API smoke → destroy.
# Does not touch Point A. FALLBACK untouched.
# ruby bin/acceptance/v3_sec_onboarding_api_key_fly.rb

require "json"
require "net/http"
require "uri"
require "open3"
require "base64"
require "fileutils"

FLY_APP = "coffeeos"
FLY_BIN = "fly"
BASE = "https://coffeeos.fly.dev"
POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
ART_DIR = "docs/operations/milestones/veha_2/artifacts/v3_sec_shop_api_keys_onboarding/mcp/fly_v495_2026-09-09"

def web_mid
  out, = Open3.capture2(FLY_BIN, "machines", "list", "-a", FLY_APP, "--json")
  machines = JSON.parse(out)
  web = machines.find { |m| m.dig("config", "metadata", "fly_process_group") == "web" && m["state"] == "started" }
  web&.dig("id") || raise("no web")
end

def fly_runner_json(mid, src)
  b64 = Base64.strict_encode64(src)
  inner = "echo #{b64} | base64 -d | /rails/bin/rails runner -"
  cmd = "sh -c #{inner.inspect}"
  out, err, st = Open3.capture3(FLY_BIN, "machine", "exec", mid, "-a", FLY_APP, "--timeout", "120", cmd)
  text = out + err
  raise "runner fail: #{text[-1200..]}" unless st.success?

  line = text.lines.map(&:strip).reverse.find { |l| l.start_with?("{") }
  raise "no json: #{text[-500..]}" unless line

  JSON.parse(line)
end

def http_get(path, headers = {})
  uri = URI.join(BASE, path)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 15
  http.read_timeout = 30
  req = Net::HTTP::Get.new(uri)
  headers.each { |k, v| req[k] = v }
  http.request(req).code.to_i
end

mid = web_mid

create = fly_runner_json(
  mid,
  <<~'RUBY'
    require "json"
    require "securerandom"
    point_a = Tenant.find("2fdee1ac-4674-41ee-b89e-87b45643f789")
    actor = User.joins(:user_roles).joins("INNER JOIN roles ON roles.id = user_roles.role_id")
              .where("roles.code ILIKE ?", "%ук%")
              .order(:created_at).first
    actor ||= User.order(:created_at).first
    slug = "mcp-key-#{SecureRandom.hex(4)}"
    tenant = nil
    result = nil
    ActiveRecord::Base.transaction do
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL app.current_user_id = #{conn.quote(actor.id.to_s)}")
      tenant = Tenant.create!(
        organization_id: point_a.organization_id,
        name: "MCP Key Onboard",
        slug: slug,
        type: "sales_point",
        status: "active",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      )
      TenantWeekdaySchedule.create!(tenant_id: tenant.id, weekday: 0, enabled: true, opens_at: "09:00", closes_at: "21:00")
      result = Platform::TenantOnboarding::Provision.call(
        tenant: tenant,
        actor_user_id: actor.id,
        module_params: {}
      )
    end
    key_count = Rls::GucContext.with_shop_api_key_lookup {
      ShopApiKey.usable.where(tenant_id: tenant.id, global_ops: false).count
    }
    point_a_keys = Rls::GucContext.with_shop_api_key_lookup {
      ShopApiKey.usable.where(tenant_id: point_a.id, global_ops: false).count
    }
    puts JSON.generate(
      tenant_id: tenant.id,
      slug: tenant.slug,
      issued: !!result.dig(:shop_api_key, :raw),
      prefix: result.dig(:shop_api_key, :prefix),
      raw: result.dig(:shop_api_key, :raw),
      usable_keys: key_count,
      point_a_usable_keys: point_a_keys,
      actor_id: actor.id
    )
  RUBY
)

raw = create["raw"]
tid = create["tenant_id"]
raise "no key issued" unless create["issued"] && raw.to_s != ""
raise "Point A keys vanished" if create["point_a_usable_keys"].to_i < 1

checks = []
checks << { id: "new_key_on_new_tenant", http: http_get("/shop/api/cart?tenant_id=#{tid}", "X-Shop-Api-Key" => raw, "X-Shop-Tenant" => tid), expect: 200 }
checks << { id: "new_key_on_point_a_401", http: http_get("/shop/api/cart?tenant_id=#{POINT_A}", "X-Shop-Api-Key" => raw, "X-Shop-Tenant" => POINT_A), expect: 401 }
checks.each { |c| c[:pass] = c[:http] == c[:expect] }

destroy = fly_runner_json(
  mid,
  <<~RUBY
    require "json"
    tid = #{tid.inspect}
    point_a = "2fdee1ac-4674-41ee-b89e-87b45643f789"
    t = Tenant.find(tid)
    raise "refusing to delete Point A" if tid == point_a
    key_ids = Rls::GucContext.with_shop_api_key_lookup { ShopApiKey.where(tenant_id: tid).pluck(:id) }
    ActiveRecord::Base.transaction do
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL app.current_tenant_id = #{ActiveRecord::Base.connection.quote(tid)}")
      ProductTenantSetting.where(tenant_id: tid).delete_all
      TenantWeekdaySchedule.where(tenant_id: tid).delete_all
      FeatureFlag.where(tenant_id: tid).delete_all
      PointCampaignSetting.where(point_id: tid).delete_all if defined?(PointCampaignSetting)
      Rls::GucContext.with_shop_api_key_lookup { ShopApiKey.where(tenant_id: tid).delete_all }
      t.destroy!
    end
    gone = Tenant.find_by(id: tid).nil?
    keys_gone = Rls::GucContext.with_shop_api_key_lookup { ShopApiKey.where(id: key_ids).count }.zero?
    a_ok = Tenant.exists?(point_a)
    puts JSON.generate(destroyed: gone, keys_gone: keys_gone, point_a_ok: a_ok, slug: #{create['slug'].inspect})
  RUBY
)

status = checks.all? { |c| c[:pass] } && destroy["destroyed"] && destroy["keys_gone"] && destroy["point_a_ok"] ? "PASS" : "FAIL"

FileUtils.mkdir_p(ART_DIR)
art = {
  date: "2026-09-09",
  fly_version: 495,
  deployment: "deployment-01M22JRN95TXRSV1PQDN49227M",
  tenant_slug: create["slug"],
  prefix: create["prefix"],
  issued: create["issued"],
  usable_keys_before_delete: create["usable_keys"],
  point_a_untouched: create["point_a_usable_keys"].to_i >= 1 && destroy["point_a_ok"],
  checks: checks.map { |c| c.slice(:id, :http, :expect, :pass) },
  destroyed: destroy,
  fallback_disabled: false,
  status: status
}
# never write raw
File.write(File.join(ART_DIR, "mcp_result.json"), JSON.pretty_generate(art))
File.write(
  File.join(ART_DIR, "MCP_RESULT.md"),
  <<~MD
    # Onboarding shop API key — Fly v495

    **Status:** **#{status}**
    - Created `#{create['slug']}` via Provision → key prefix `#{create['prefix']}`
    - API: new key on new tenant 200 · on Point A 401
    - Deleted test tenant + keys · Point A untouched
    - FALLBACK still ON
  MD
)
puts JSON.pretty_generate(art)
exit(status == "PASS" ? 0 : 1)
