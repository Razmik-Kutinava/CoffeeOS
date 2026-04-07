# frozen_string_literal: true

namespace :test do
  desc "Создать тестовых пользователей с разными ролями для тестирования входа"
  task create_test_users: :environment do
    puts "=== Создание тестовых данных для входа ==="

    org = Organization.find_or_create_by!(slug: "test-franchise-org") do |o|
      o.name = "Тестовая франшиза"
    end
    puts "✓ Организация: #{org.name} (#{org.slug})"

    tenant = Tenant.find_or_create_by!(slug: "test-cafe") do |t|
      t.name = "Тестовая кофейня"
      t.country = "RU"
      t.currency = "RUB"
      t.type = "sales_point"
      t.status = "active"
    end
    tenant.update!(organization_id: org.id) if tenant.organization_id != org.id
    puts "✓ Tenant: #{tenant.name} (#{tenant.slug}) → org #{org.slug}"

    tenant2 = Tenant.find_or_create_by!(slug: "test-cafe-2") do |t|
      t.name = "Тестовая кофейня 2"
      t.country = "RU"
      t.currency = "RUB"
      t.type = "sales_point"
      t.status = "active"
      t.organization = org
    end
    tenant2.update!(organization_id: org.id) if tenant2.organization_id != org.id
    puts "✓ Вторая точка (переключатель франчайзи): #{tenant2.name}"

    roles_data = [
      { code: "barista", name: "Бариста" },
      { code: "shift_manager", name: "Сменный менеджер" },
      { code: "office_manager", name: "Офис-менеджер" },
      { code: "prep_kitchen_worker", name: "Работник кухни" },
      { code: "prep_kitchen_manager", name: "Менеджер кухни" },
      { code: "franchise_manager", name: "Менеджер франшизы (владелец сети)" },
      { code: "ук_global_admin", name: "УК — глобальный админ" },
      { code: "ук_country_manager", name: "Менеджер страны" },
      { code: "ук_billing_admin", name: "Биллинг админ" },
      { code: "blog_editor", name: "Редактор блога" }
    ]

    roles = {}
    roles_data.each do |role_data|
      role = Role.find_or_create_by!(code: role_data[:code]) do |r|
        r.name = role_data[:name]
        r.is_system = true
      end
      roles[role_data[:code]] = role
      puts "✓ Роль: #{role.name} (#{role.code})"
    end

    test_password = "test123456"

    users_data = [
      { email: "barista@test.com", name: "Бариста Тест", roles: ["barista"] },
      { email: "manager@test.com", name: "Менеджер Тест", roles: ["shift_manager"] },
      { email: "office@test.com", name: "Офис Тест", roles: ["office_manager"] },
      { email: "kitchen-manager@test.com", name: "Менеджер кухни Тест", roles: ["prep_kitchen_manager"] },
      { email: "kitchen@test.com", name: "Кухня Тест", roles: ["prep_kitchen_worker"] },
      { email: "franchise@test.com", name: "Франчайзи Тест", roles: ["franchise_manager"], organization_id: org.id },
      { email: "uk@test.com", name: "УК Тест", roles: ["ук_global_admin"] },
      { email: "multi@test.com", name: "Мульти Роль", roles: %w[barista shift_manager] },
      { phone: "+79991234567", name: "Телефон Тест", roles: ["barista"] },
      { email: "blocked@test.com", name: "Заблокированный", roles: ["barista"], status: "blocked" },
      { email: "blog_editor@test.com", name: "Редактор блога", roles: ["blog_editor"] },
      { email: "blog_editor2@test.com", name: "Редактор блога 2", roles: ["blog_editor"] }
    ]

    users_data.each do |user_data|
      user = User.find_or_initialize_by(
        email: user_data[:email],
        phone: user_data[:phone]
      )

      user.name = user_data[:name]
      user.tenant_id = tenant.id
      user.organization_id = user_data[:organization_id]
      user.password = test_password
      user.status = user_data[:status] || "active"

      if user.save
        user.user_roles.destroy_all

        user_data[:roles].each do |role_code|
          UserRole.create!(
            user: user,
            role: roles[role_code],
            tenant_id: tenant.id
          )
        end

        identifier = user_data[:email] || user_data[:phone]
        puts "✓ Пользователь: #{user.name} (#{identifier}) — #{user_data[:roles].join(', ')}"
      else
        puts "✗ Ошибка: #{user_data[:name]} — #{user.errors.full_messages.join(', ')}"
      end
    end

    puts "\n=== Готово ==="
    puts "Пароль для всех (кроме заблокированного): #{test_password}"
    puts ""
    puts "Параллельные разные пользователи: разные поддомены *.localhost или 127.0.0.1 vs localhost (см. docs/features/ADMIN_PANELS_LOGIN.md)."
    puts ""
    puts "Два входа в «админки»:"
    puts "  1) Франчайзи (несколько точек, как офис) → логин franchise@test.com → после входа /manager/"
    puts "  2) УК (платформа) → логин uk@test.com → после входа /admin/"
    puts ""
    puts "Офис одной точки: office@test.com → /manager/"
    puts "Старый admin@test.com удалён из сценария; используй franchise@test.com и uk@test.com."
    puts ""
    puts "Блог (после db:migrate и bin/rails blog:seed):"
    puts "  http://localhost:3001/blog"
    puts "  Редакторы: blog_editor@test.com / blog_editor2@test.com — пароль как у остальных (#{test_password})"
  end

  desc "Удалить всех тестовых пользователей (из списка задачи)"
  task cleanup_test_users: :environment do
    puts "=== Удаление тестовых пользователей ==="

    test_emails = %w[
      barista@test.com manager@test.com office@test.com kitchen-manager@test.com
      kitchen@test.com franchise@test.com uk@test.com admin@test.com multi@test.com blocked@test.com
      blog_editor@test.com blog_editor2@test.com
    ]

    test_phone = "+79991234567"

    deleted_count = 0
    test_emails.each do |email|
      user = User.find_by(email: email)
      if user
        user.destroy
        deleted_count += 1
        puts "✓ Удалён: #{email}"
      end
    end

    phone_user = User.find_by(phone: test_phone)
    if phone_user
      phone_user.destroy
      deleted_count += 1
      puts "✓ Удалён: #{test_phone}"
    end

    puts "\n=== Удалено: #{deleted_count} ==="
  end
end
