namespace :rls do
  desc "Check RLS policies for all tables with tenant_id"
  task check: :environment do
    puts "🔍 Checking RLS status...\n\n"
    
    # Найти все таблицы с tenant_id
    tables_with_tenant = ActiveRecord::Base.connection.tables.select do |t|
      ActiveRecord::Base.connection.columns(t).any? { |c| c.name == 'tenant_id' }
    end
    
    tables_with_tenant.each do |table|
      # Проверить RLS статус
      rls_status = ActiveRecord::Base.connection.execute(<<-SQL)
        SELECT rowsecurity 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename = '#{table}'
      SQL
      
      # Проверить политики
      policies = ActiveRecord::Base.connection.execute(<<-SQL)
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = '#{table}'
      SQL
      
      status = rls_status.first['rowsecurity'] ? '✅' : '❌'
      
      if policies.empty?
        puts "❌ #{table}: No RLS policies"
      else
        policy_names = policies.map { |p| p['policyname'] }.join(', ')
        puts "✅ #{table}: #{policy_names}"
      end
    end
    
    puts "\n✅ = RLS enabled, ❌ = RLS disabled"
  end
  
  desc "Test RLS isolation between tenants"
  task test_isolation: :environment do
    puts "🧪 Testing RLS isolation...\n\n"
    
    tenant_a = Tenant.first
    tenant_b = Tenant.second
    
    if tenant_a.nil? || tenant_b.nil?
      puts "❌ Need at least 2 tenants for testing"
      exit 1
    end
    
    # Создаём заказы для разных тенантов
    order_a = Order.create!(
      tenant: tenant_a,
      order_number: '#TEST-A-001',
      source: 'manual',
      status: 'accepted',
      total_amount: 100,
      final_amount: 100
    )
    
    order_b = Order.create!(
      tenant: tenant_b,
      order_number: '#TEST-B-001',
      source: 'manual',
      status: 'accepted',
      total_amount: 200,
      final_amount: 200
    )
    
    # Тест 1: tenant_a видит только свои заказы
    ActiveRecord::Base.connection.execute(
      "SET LOCAL app.current_tenant_id = '#{tenant_a.id}'"
    )
    
    visible_orders = Order.all.to_a
    has_order_a = visible_orders.any? { |o| o.id == order_a.id }
    has_order_b = visible_orders.any? { |o| o.id == order_b.id }
    
    if has_order_a && !has_order_b
      puts "✅ Test 1 passed: tenant_a sees only own orders"
    else
      puts "❌ Test 1 failed: tenant_a sees other tenant's orders"
    end
    
    # Тест 2: tenant_b видит только свои заказы
    ActiveRecord::Base.connection.execute(
      "SET LOCAL app.current_tenant_id = '#{tenant_b.id}'"
    )
    
    visible_orders = Order.all.to_a
    has_order_a = visible_orders.any? { |o| o.id == order_a.id }
    has_order_b = visible_orders.any? { |o| o.id == order_b.id }
    
    if has_order_b && !has_order_a
      puts "✅ Test 2 passed: tenant_b sees only own orders"
    else
      puts "❌ Test 2 failed: tenant_b sees other tenant's orders"
    end
    
    # Очистка
    ActiveRecord::Base.connection.execute("RESET app.current_tenant_id")
    order_a.destroy
    order_b.destroy
    
    puts "\n✅ RLS isolation test completed"
  end
end
