# frozen_string_literal: true

namespace :shop do
  namespace :catalog do
    desc "Загрузить каталог витрины (db/seeds_shop_catalog.rb: категории, товары, PTS на всех тенантах). " \
         "В production обязателен ALLOW_SHOP_CATALOG_LOAD=1"
    task load: :environment do
      if Rails.env.production? && ENV.fetch("ALLOW_SHOP_CATALOG_LOAD", "").to_s != "1"
        abort <<~MSG.squish
          Отказ: в production загрузка каталога только с ALLOW_SHOP_CATALOG_LOAD=1
          (осознанное изменение данных). Локально переменная не нужна.
        MSG
      end

      if Tenant.count.zero?
        abort <<~MSG.squish
          Нет ни одного Tenant. Сначала создай организацию и точку:
          ADMIN_PASSWORD=ваш_пароль bin/rails setup:production
          (печатает SHOP_DEFAULT_TENANT_ID для .env), затем снова shop:catalog:load.
        MSG
      end

      load Rails.root.join("db/seeds_shop_catalog.rb")
      puts "[shop:catalog:load] готово."
    end

    desc "Поднять product_tenant_settings.price ниже #{Payments::AmountLimits::MIN_CHARGE_RUB} ₽ до минимума (Т-Банк). " \
         "DRY_RUN=1 — только показать. TENANT_ID=uuid — только точка."
    task bump_min_prices: :environment do
      min = Payments::AmountLimits::MIN_CHARGE_RUB
      dry = ENV["DRY_RUN"].to_s == "1"
      scope = ProductTenantSetting.where.not(price: nil).where("price < ?", min)
      scope = scope.where(tenant_id: ENV["TENANT_ID"]) if ENV["TENANT_ID"].present?
      n = scope.count
      puts "[shop:catalog:bump_min_prices] below=#{n} min=#{min} dry_run=#{dry}"
      scope.find_each do |pts|
        puts "  #{pts.tenant_id} product=#{pts.product_id} #{pts.price} → #{min}"
        pts.update_columns(price: min, updated_at: Time.current) unless dry
      end
      puts "[shop:catalog:bump_min_prices] done"
    end
  end
end
