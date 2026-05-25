# frozen_string_literal: true

namespace :test do
  desc "Демо-пользователи для ручного/MCP входа (источник правды: Demo::EnvironmentSetup / demo:seed)"
  task create_test_users: :environment do
    puts "=== Демо-пользователи (Demo::EnvironmentSetup) ==="
    puts ""

    result = Demo::EnvironmentSetup.call(load_catalog: true)

    org = result.organization
    puts "✓ Организация: #{org.name} (#{org.slug})"
    puts "✓ Точка A: #{result.tenant_a.name} (#{result.tenant_a.slug})"
    puts "✓ Точка B: #{result.tenant_b.name} (#{result.tenant_b.slug})"
    puts "✓ Цех: #{result.tenant_kitchen.name} (#{result.tenant_kitchen.slug})"
    puts "✓ Каталог: #{result.products_count} товаров; PTS A=#{result.pts_a_count}, B=#{result.pts_b_count}"
    puts ""

    tenant_labels = { a: "A", b: "B", kitchen: "цех" }
    panel_for = lambda do |roles|
      return "/admin" if roles.include?("ук_global_admin")
      return "/prep_kitchen" if roles.any? { |r| r.start_with?("prep_kitchen") }
      return "/barista" if roles == %w[barista]
      return "/manager" if roles.intersect?(%w[shift_manager general_manager franchise_manager])

      "—"
    end

    Demo::EnvironmentSetup::USERS.each do |spec|
      tenant_label = tenant_labels.fetch(spec[:tenant])
      roles = spec[:roles].join(", ")
      panel = panel_for.call(spec[:roles])
      puts "  #{spec[:email].ljust(32)} | #{roles.ljust(22)} | tenant #{tenant_label} → #{panel}"
    end

    puts ""
    puts "Пароль всех demo-пользователей: #{Demo::EnvironmentSetup::DEMO_PASSWORD}"
    puts ""
    puts "Дубль задачи = demo:seed. Канон: app/services/demo/environment_setup.rb"
    puts "Док: docs/operations/milestones/veha_1/DEMO_LOGINS.md"
    puts ""
    puts "MCP / ручной обход блока D: docs/operations/milestones/veha_1/CHECKLIST.md §D"
  end

  desc "Удалить demo-пользователей (@demo.coffeeos.local) и опциональных test@ extras"
  task cleanup_test_users: :environment do
    puts "=== Удаление demo / test login пользователей ==="

    emails = Demo::EnvironmentSetup::USERS.map { |u| u[:email].downcase }
    deleted_count = 0

    emails.each do |email|
      user = User.find_by(email: email)
      next unless user

      user.destroy
      deleted_count += 1
      puts "✓ Удалён: #{email}"
    end

    puts "\n=== Удалено: #{deleted_count} ==="
    puts "Организация/tenants demo не трогаем (идемпотентный demo:seed пересоздаст users)."
  end
end
