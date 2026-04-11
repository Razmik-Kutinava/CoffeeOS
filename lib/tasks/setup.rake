# frozen_string_literal: true

namespace :setup do
  desc "Первичная настройка продакшн-базы: роли, организация, точка, admin и blog_editor"
  task production: :environment do
    puts "=== CoffeeOS: первичная настройка production ==="

    # 1. Роли
    roles_data = [
      { code: "barista",              name: "Бариста" },
      { code: "shift_manager",        name: "Сменный менеджер" },
      { code: "office_manager",       name: "Офис-менеджер" },
      { code: "prep_kitchen_worker",  name: "Работник кухни" },
      { code: "prep_kitchen_manager", name: "Менеджер кухни" },
      { code: "franchise_manager",    name: "Менеджер франшизы" },
      { code: "ук_global_admin",      name: "УК — глобальный админ" },
      { code: "ук_country_manager",   name: "Менеджер страны" },
      { code: "ук_billing_admin",     name: "Биллинг админ" },
      { code: "blog_editor",          name: "Редактор блога" }
    ]
    roles = {}
    roles_data.each do |r|
      role = Role.find_or_create_by!(code: r[:code]) { |x| x.name = r[:name]; x.is_system = true }
      roles[r[:code]] = role
    end
    puts "✓ Роли: #{roles.keys.join(', ')}"

    # 2. Организация
    org_name = ENV.fetch("ORG_NAME", "CoffeeOS")
    org_slug = ENV.fetch("ORG_SLUG", "coffeeos")
    org = Organization.find_or_create_by!(slug: org_slug) { |o| o.name = org_name }
    puts "✓ Организация: #{org.name} (#{org.slug})"

    # 3. Точка (tenant)
    tenant_name = ENV.fetch("TENANT_NAME", org_name)
    tenant_slug = ENV.fetch("TENANT_SLUG", org_slug)
    tenant = Tenant.find_or_create_by!(slug: tenant_slug) do |t|
      t.name         = tenant_name
      t.type         = "sales_point"
      t.status       = "active"
      t.country      = "RU"
      t.currency     = "RUB"
      t.organization = org
    end
    tenant.update!(status: "active") unless tenant.status == "active"
    puts "✓ Точка: #{tenant.name} (#{tenant.slug}) id=#{tenant.id}"
    puts ""
    puts "  >> SHOP_DEFAULT_TENANT_ID=#{tenant.id}"
    puts ""

    # 4. UK-admin
    admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@coffeeos.local")
    admin_password = ENV.fetch("ADMIN_PASSWORD") { abort "Укажите ADMIN_PASSWORD=..." }
    admin = User.find_or_initialize_by(email: admin_email.downcase.strip)
    admin.name      = ENV.fetch("ADMIN_NAME", "Admin")
    admin.status    = "active"
    admin.tenant_id = tenant.id
    admin.password  = admin_password
    admin.save!
    UserRole.find_or_create_by!(user: admin, role: roles["ук_global_admin"])
    puts "✓ UK-admin: #{admin.email} (пароль задан)"

    # 5. Blog editor (тот же пользователь или отдельный)
    blog_email    = ENV.fetch("BLOG_EMAIL", admin_email)
    blog_password = ENV.fetch("BLOG_PASSWORD", admin_password)
    if blog_email == admin_email
      blog_user = admin
    else
      blog_user = User.find_or_initialize_by(email: blog_email.downcase.strip)
      blog_user.name      = ENV.fetch("BLOG_NAME", "Blog Editor")
      blog_user.status    = "active"
      blog_user.tenant_id = tenant.id
      blog_user.password  = blog_password
      blog_user.save!
    end
    UserRole.find_or_create_by!(user: blog_user, role: roles["blog_editor"])
    puts "✓ Blog editor: #{blog_user.email}"

    # 6. Каталог витрины
    puts ""
    puts "Загружаем каталог витрины..."
    load Rails.root.join("db/seeds_shop_catalog.rb")

    puts ""
    puts "=== Готово ==="
    puts "Задай в Render Environment:"
    puts "  SHOP_DEFAULT_TENANT_ID=#{tenant.id}"
    puts ""
    puts "Входы:"
    puts "  /admin  — #{admin_email}"
    puts "  /blog   — #{blog_email} (long-press на футере)"
    puts "  /shop   — откроется с каталогом"
  end
end
