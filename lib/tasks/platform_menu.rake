# frozen_string_literal: true

namespace :platform do
  namespace :menu do
    desc "Синхронизировать ProductTenantSetting для всех товаров на все точки (витрина)"
    task sync_pts: :environment do
      user = Platform::Menu::ProductTenantSync.fallback_uk_user
      abort "Нет пользователя с ролью ук_global_admin" unless user

      Platform::Menu::ProductTenantSync.repair_missing_pts!(user: user)
      puts "[platform:menu:sync_pts] готово."
    end
  end
end
