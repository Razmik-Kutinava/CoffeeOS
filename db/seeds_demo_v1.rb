# frozen_string_literal: true

# Демо-среда В1: 1 org, 2 точки продаж, заготовочный цех, каталог CoffeeOS, PTS, пользователи.
# Идемпотентно. Пароль всех demo-пользователей: Demo::EnvironmentSetup::DEMO_PASSWORD

puts "[demo] Настройка демо-среды В1..."
result = Demo::EnvironmentSetup.call(load_catalog: true)

def demo_shop_public_url(tenant)
  path = Platform::TenantOnboarding::UrlBuilder.shop_url_for(tenant)
  return path unless path.start_with?("/")

  host = ENV.fetch("APP_HOST", "localhost:3001")
  scheme = Rails.env.production? ? "https" : "http"
  "#{scheme}://#{host}#{path}"
end

puts <<~MSG

[demo] Готово:
  Организация: #{result.organization.name} (#{result.organization.slug})
  Точка A: #{result.tenant_a.name} (#{result.tenant_a.slug}) id=#{result.tenant_a.id}
  Точка B: #{result.tenant_b.name} (#{result.tenant_b.slug}) id=#{result.tenant_b.id}
  Заготовочный цех: #{result.tenant_kitchen.name} (#{result.tenant_kitchen.slug}) id=#{result.tenant_kitchen.id}
  Активных продуктов: #{result.products_count}
  PTS: A=#{result.pts_a_count}, B=#{result.pts_b_count}
  Demo-пользователей: #{result.users_count} (в т.ч. pk-manager / pk-worker → /prep_kitchen)
  Пароль: #{Demo::EnvironmentSetup::DEMO_PASSWORD}
  Shop A: #{demo_shop_public_url(result.tenant_a)}
  Shop B: #{demo_shop_public_url(result.tenant_b)}

MSG
