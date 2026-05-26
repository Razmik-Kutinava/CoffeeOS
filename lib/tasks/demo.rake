# frozen_string_literal: true

namespace :demo do
  desc "Демо-среда В1: 1 org, 2 точки продаж, заготовочный цех, каталог, PTS, пользователи с ролями"
  task seed: :environment do
    load Rails.root.join("db/seeds_demo_v1.rb")
  end

  desc "URL витрин всех активных точек (режим поддомен или ?tenant_id= — см. docs/operations/SHOP_URL_MODES.md)"
  task shop_urls: :environment do
    base = Platform::TenantOnboarding::UrlBuilder.shop_base_domain
    mode = base.present? ? "A (поддомен #{base})" : "B (Fly demo / без SHOP_BASE_DOMAIN)"
    host = ENV.fetch("APP_HOST", "localhost:3001")

    puts "[demo:shop_urls] режим #{mode}"
    puts "[demo:shop_urls] APP_HOST=#{host}" if base.blank? && Rails.env.production?

    Tenant.where(status: "active").order(:slug).find_each do |t|
      url = Platform::TenantOnboarding::UrlBuilder.shop_url_for(t)
      url = "https://#{host}#{url}" if url.start_with?("/")
      puts "#{t.slug}\t#{t.id}\t#{url}"
    end
  end
end