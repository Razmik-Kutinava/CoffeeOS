# frozen_string_literal: true

namespace :demo do
  desc "Демо-среда В1: 1 org, 2 точки продаж, заготовочный цех, каталог, PTS, пользователи с ролями"
  task seed: :environment do
    load Rails.root.join("db/seeds_demo_v1.rb")
  end

  # HTTPS-фото для демо-витрины (не зависят от public/uploads — работают на Fly после rake).
  CATALOG_IMAGE_URLS = [
    "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=800&q=80"
  ].freeze

  desc "Первые N товаров витрины (demo-point-a): image_url = HTTPS Unsplash (локально и на Fly)"
  task catalog_images: :environment do
    slug = ENV.fetch("DEMO_CATALOG_IMAGES_TENANT", "demo-point-a")
    limit = ENV.fetch("DEMO_CATALOG_IMAGES_LIMIT", "5").to_i
    tenant = Tenant.find_by(slug: slug) || Tenant.order(:created_at).first
    abort("[demo:catalog_images] tenant not found (slug=#{slug})") unless tenant

    products = Shop::Catalog.tenant_menu(tenant.id)[:products].first(limit)
    abort("[demo:catalog_images] no products") if products.empty?

    products.each_with_index do |product, i|
      url = CATALOG_IMAGE_URLS[i % CATALOG_IMAGE_URLS.size]
      product.update_column(:image_url, url)
      puts "[demo:catalog_images] #{i + 1}. #{product.name} -> #{url[0, 60]}…"
    end
    puts "[demo:catalog_images] OK tenant=#{tenant.slug} count=#{products.size}"
  end

  desc "URL витрин всех активных точек (режим поддомен или ?tenant_id= — см. docs/operations/dev/SHOP_URL_MODES.md)"
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
