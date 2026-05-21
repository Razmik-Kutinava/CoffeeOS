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
  end
end
