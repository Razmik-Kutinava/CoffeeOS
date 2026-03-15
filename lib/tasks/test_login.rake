namespace :test do
  desc "Создать тестовых пользователей с разными ролями для тестирования входа"
  task create_test_users: :environment do
    puts "=== Создание тестовых данных для входа ==="
    
    # Создаем тестовый tenant
    tenant = Tenant.find_or_create_by!(slug: 'test-cafe') do |t|
      t.name = 'Тестовая кофейня'
      t.country = 'RU'
      t.currency = 'RUB'
      t.type = 'sales_point'
      t.status = 'active'
    end
    puts "✓ Tenant создан: #{tenant.name} (#{tenant.id})"
    
    # Создаем роли
    roles_data = [
      { code: 'barista', name: 'Бариста' },
      { code: 'shift_manager', name: 'Сменный менеджер' },
      { code: 'office_manager', name: 'Офис-менеджер' },
      { code: 'prep_kitchen_worker', name: 'Работник кухни' },
      { code: 'prep_kitchen_manager', name: 'Менеджер кухни' },
      { code: 'franchise_manager', name: 'Менеджер франшизы' },
      { code: 'ук_global_admin', name: 'Глобальный админ' },
      { code: 'ук_country_manager', name: 'Менеджер страны' },
      { code: 'ук_billing_admin', name: 'Биллинг админ' }
    ]
    
    roles = {}
    roles_data.each do |role_data|
      role = Role.find_or_create_by!(code: role_data[:code]) do |r|
        r.name = role_data[:name]
        r.is_system = true
      end
      roles[role_data[:code]] = role
      puts "✓ Роль создана: #{role.name} (#{role.code})"
    end
    
    # Создаем тестовых пользователей с разными ролями
    test_password = 'test123456'
    
    users_data = [
      { email: 'barista@test.com', name: 'Бариста Тест', roles: ['barista'] },
      { email: 'manager@test.com', name: 'Менеджер Тест', roles: ['shift_manager'] },
      { email: 'office@test.com', name: 'Офис Тест', roles: ['office_manager'] },
      { email: 'kitchen@test.com', name: 'Кухня Тест', roles: ['prep_kitchen_worker'] },
      { email: 'admin@test.com', name: 'Админ Тест', roles: ['franchise_manager'] },
      { email: 'multi@test.com', name: 'Мульти Роль', roles: ['barista', 'shift_manager'] },
      { phone: '+79991234567', name: 'Телефон Тест', roles: ['barista'] },
      { email: 'blocked@test.com', name: 'Заблокированный', roles: ['barista'], status: 'blocked' }
    ]
    
    users_data.each do |user_data|
      user = User.find_or_initialize_by(
        email: user_data[:email],
        phone: user_data[:phone]
      )
      
      user.name = user_data[:name]
      user.tenant_id = tenant.id
      user.password = test_password
      user.status = user_data[:status] || 'active'
      
      if user.save
        # Удаляем старые роли
        user.user_roles.destroy_all
        
        # Добавляем новые роли
        user_data[:roles].each do |role_code|
          UserRole.create!(
            user: user,
            role: roles[role_code],
            tenant_id: tenant.id
          )
        end
        
        identifier = user_data[:email] || user_data[:phone]
        puts "✓ Пользователь создан: #{user.name} (#{identifier}) - роли: #{user_data[:roles].join(', ')}"
      else
        puts "✗ Ошибка создания пользователя #{user_data[:name]}: #{user.errors.full_messages.join(', ')}"
      end
    end
    
    puts "\n=== Тестовые данные созданы ==="
    puts "Пароль для всех пользователей: #{test_password}"
    puts "\nТестовые пользователи:"
    puts "  - barista@test.com (роль: barista)"
    puts "  - manager@test.com (роль: shift_manager)"
    puts "  - office@test.com (роль: office_manager)"
    puts "  - kitchen@test.com (роль: prep_kitchen_worker)"
    puts "  - admin@test.com (роль: franchise_manager)"
    puts "  - multi@test.com (роли: barista, shift_manager)"
    puts "  - +79991234567 (роль: barista)"
    puts "  - blocked@test.com (заблокирован)"
  end
  
  desc "Удалить всех тестовых пользователей"
  task cleanup_test_users: :environment do
    puts "=== Удаление тестовых данных ==="
    
    test_emails = [
      'barista@test.com',
      'manager@test.com',
      'office@test.com',
      'kitchen@test.com',
      'admin@test.com',
      'multi@test.com',
      'blocked@test.com'
    ]
    
    test_phone = '+79991234567'
    
    deleted_count = 0
    
    test_emails.each do |email|
      user = User.find_by(email: email)
      if user
        user.destroy
        deleted_count += 1
        puts "✓ Удален: #{email}"
      end
    end
    
    phone_user = User.find_by(phone: test_phone)
    if phone_user
      phone_user.destroy
      deleted_count += 1
      puts "✓ Удален: #{test_phone}"
    end
    
    puts "\n=== Удалено пользователей: #{deleted_count} ==="
  end
end
