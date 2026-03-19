namespace :test do
  desc "Fill all barista dashboard tables with test data"
  task fill_barista_data: :environment do
    puts "🧪 Заполнение всех таблиц БД для табло баристы..."
    
    # 1. Tenant
    tenant = Tenant.find_or_create_by!(name: 'Тестовая кофейня') do |t|
      t.type = 'sales_point'
      t.is_active = true
      t.slug = 'test-cafe'
      t.country = 'RU'
      t.currency = 'RUB'
    end
    Current.tenant_id = tenant.id
    puts "✅ Tenant: #{tenant.name} (ID: #{tenant.id})"
    
    # 2. Roles
    barista_role = Role.find_or_create_by!(code: 'barista') do |r|
      r.name = 'Бариста'
      r.description = 'Бариста'
      r.is_system = true
    end
    puts "✅ Role: #{barista_role.name} (code: #{barista_role.code})"
    
    # 3. User
    barista = User.find_or_initialize_by(email: 'barista@test.com')
    barista.name = 'Бариста Тест'
    barista.phone = '+79991234567'
    barista.tenant_id = tenant.id
    barista.status = 'active'
    barista.password = 'test123456'
    barista.save!
    
    unless barista.roles.include?(barista_role)
      UserRole.create!(user: barista, role: barista_role, tenant_id: tenant.id)
    end
    puts "✅ User: #{barista.name} (ID: #{barista.id}, roles: #{barista.roles.pluck(:code).join(', ')})"
    
    # 4. Categories
    categories_data = [
      { name: 'Кофе', slug: 'coffee', sort_order: 1 },
      { name: 'Чай', slug: 'tea', sort_order: 2 },
      { name: 'Еда', slug: 'food', sort_order: 3 },
      { name: 'Десерты', slug: 'desserts', sort_order: 4 }
    ]
    
    categories = []
    categories_data.each do |cat_data|
      category = Category.find_or_create_by!(slug: cat_data[:slug]) do |c|
        c.name = cat_data[:name]
        c.sort_order = cat_data[:sort_order]
        c.is_active = true
      end
      categories << category
      puts "✅ Category: #{category.name} (ID: #{category.id}, slug: #{category.slug})"
    end
    
    # 5. Products
    products_data = [
      { name: 'Капучино М', category: 'coffee', price: 350, sort_order: 1 },
      { name: 'Капучино L', category: 'coffee', price: 400, sort_order: 2 },
      { name: 'Латте М', category: 'coffee', price: 350, sort_order: 3 },
      { name: 'Латте L', category: 'coffee', price: 400, sort_order: 4 },
      { name: 'Американо M', category: 'coffee', price: 250, sort_order: 5 },
      { name: 'Эспрессо', category: 'coffee', price: 200, sort_order: 6 },
      { name: 'Флэт Уайт', category: 'coffee', price: 380, sort_order: 7 },
      { name: 'Раф кофе', category: 'coffee', price: 420, sort_order: 8 },
      { name: 'Чай зелёный', category: 'tea', price: 200, sort_order: 1 },
      { name: 'Чай чёрный', category: 'tea', price: 200, sort_order: 2 },
      { name: 'Чай с лимоном', category: 'tea', price: 220, sort_order: 3 },
      { name: 'Круассан', category: 'food', price: 150, sort_order: 1 },
      { name: 'Сэндвич', category: 'food', price: 280, sort_order: 2 },
      { name: 'Салат', category: 'food', price: 320, sort_order: 3 },
      { name: 'Пончик', category: 'desserts', price: 120, sort_order: 1 },
      { name: 'Чизкейк', category: 'desserts', price: 250, sort_order: 2 },
      { name: 'Торт', category: 'desserts', price: 180, sort_order: 3 },
      { name: 'Печенье', category: 'desserts', price: 80, sort_order: 4 }
    ]
    
    products = []
    products_data.each do |prod_data|
      category = categories.find { |c| c.slug == prod_data[:category] }
      product = Product.find_or_create_by!(name: prod_data[:name]) do |p|
        p.category_id = category.id
        p.sort_order = prod_data[:sort_order]
        p.is_active = true
      end
      
      # ProductTenantSetting
      setting = ProductTenantSetting.find_or_create_by!(
        product_id: product.id,
        tenant_id: tenant.id
      ) do |s|
        s.price = prod_data[:price]
        s.is_enabled = true
        s.is_sold_out = false
        s.stock_quantity = rand(10..100)
      end
      
      products << product
      puts "✅ Product: #{product.name} (#{setting.price} ₽, stock: #{setting.stock_quantity})"
    end
    
    # 6. CashShift
    cash_shift = CashShift.find_or_create_by!(
      tenant_id: tenant.id,
      status: 'open'
    ) do |cs|
      cs.opened_at = 2.hours.ago
      cs.opened_by_id = barista.id
      cs.opening_cash = 5000.0
    end
    puts "✅ CashShift: ##{cash_shift.id} (opened: #{cash_shift.opened_at.strftime('%H:%M')})"
    
    # 7. ShiftStaff
    shift_staff = ShiftStaff.find_or_create_by!(
      cash_shift_id: cash_shift.id,
      user_id: barista.id
    ) do |ss|
      ss.status = 'active'
      ss.joined_at = cash_shift.opened_at
    end
    puts "✅ ShiftStaff: User ##{barista.id} on shift ##{cash_shift.id}"
    
    # 8. Orders (accepted, preparing, ready)
    order_statuses = [
      { status: 'accepted', count: 4 },
      { status: 'preparing', count: 3 },
      { status: 'ready', count: 2 }
    ]
    sources = ['kiosk', 'app', 'manual']
    
    order_statuses.each do |status_data|
      status_data[:count].times do |i|
        order = Order.create!(
          tenant_id: tenant.id,
          cash_shift_id: cash_shift.id,
          order_number: "ORD-#{Time.current.strftime('%Y%m%d')}-#{status_data[:status][0..2].upcase}-#{i + 1}",
          status: status_data[:status],
          source: sources.sample,
          final_amount: 0, # Will be calculated
          created_at: (rand(1..30)).minutes.ago
        )
        
        # OrderItems
        num_items = rand(1..4)
        selected_products = products.sample(num_items)
        total = 0
        
        selected_products.each do |product|
          setting = product.product_tenant_settings.find_by(tenant_id: tenant.id)
          quantity = rand(1..3)
          item_total = setting.price * quantity
          total += item_total
          
          OrderItem.create!(
            order_id: order.id,
            product_id: product.id,
            product_name: product.name,
            quantity: quantity,
            price: setting.price,
            total_price: item_total
          )
        end
        
        order.update_column(:final_amount, total)
        
        # Payment
        Payment.create!(
          order_id: order.id,
          tenant_id: tenant.id,
          amount: total,
          method: ['card', 'cash', 'sbp'].sample,
          status: 'succeeded',
          processed_at: order.created_at + 1.minute
        )
        
        # OrderStatusLog
        OrderStatusLog.create!(
          order_id: order.id,
          tenant_id: tenant.id,
          status_from: 'pending_payment',
          status_to: status_data[:status],
          changed_by_id: barista.id,
          source: 'barista',
          created_at: order.created_at
        )
        
        puts "✅ Order: #{order.order_number} (#{status_data[:status]}, #{total} ₽)"
      end
    end
    
    # 9. History Orders (closed, cancelled, issued)
    history_statuses = [
      { status: 'closed', count: 4 },
      { status: 'cancelled', count: 2 },
      { status: 'issued', count: 3 }
    ]
    
    history_statuses.each do |status_data|
      status_data[:count].times do |i|
        order = Order.create!(
          tenant_id: tenant.id,
          cash_shift_id: cash_shift.id,
          order_number: "HIST-#{Time.current.strftime('%Y%m%d')}-#{status_data[:status][0..2].upcase}-#{i + 1}",
          status: status_data[:status],
          source: sources.sample,
          final_amount: 0,
          created_at: (i + 1).hours.ago
        )
        
        num_items = rand(1..3)
        selected_products = products.sample(num_items)
        total = 0
        
        selected_products.each do |product|
          setting = product.product_tenant_settings.find_by(tenant_id: tenant.id)
          quantity = rand(1..2)
          item_total = setting.price * quantity
          total += item_total
          
          OrderItem.create!(
            order_id: order.id,
            product_id: product.id,
            product_name: product.name,
            quantity: quantity,
            price: setting.price,
            total_price: item_total
          )
        end
        
        order.update_column(:final_amount, total)
        
        if status_data[:status] != 'cancelled'
          Payment.create!(
            order_id: order.id,
            tenant_id: tenant.id,
            amount: total,
            method: ['card', 'cash'].sample,
            status: 'succeeded',
            processed_at: order.created_at + 1.minute
          )
        end
        
        OrderStatusLog.create!(
          order_id: order.id,
          tenant_id: tenant.id,
          status_from: 'accepted',
          status_to: status_data[:status],
          changed_by_id: barista.id,
          source: 'barista',
          created_at: order.created_at
        )
        
        puts "✅ History Order: #{order.order_number} (#{status_data[:status]}, #{total} ₽)"
      end
    end
    
    # Summary
    puts "\n📊 Итоговая статистика:"
    puts "  ✅ Tenant: #{tenant.name}"
    puts "  ✅ Categories: #{categories.count}"
    puts "  ✅ Products: #{products.count}"
    puts "  ✅ ProductTenantSettings: #{ProductTenantSetting.where(tenant_id: tenant.id).count}"
    puts "  ✅ CashShift: ##{cash_shift.id}"
    puts "  ✅ ShiftStaff: #{ShiftStaff.where(cash_shift_id: cash_shift.id).count}"
    puts "  ✅ Orders (active): #{Order.where(tenant_id: tenant.id, status: ['accepted', 'preparing', 'ready']).count}"
    puts "  ✅ Orders (history): #{Order.where(tenant_id: tenant.id, status: ['closed', 'cancelled', 'issued']).count}"
    puts "  ✅ OrderItems: #{OrderItem.joins(:order).where(orders: { tenant_id: tenant.id }).count}"
    puts "  ✅ Payments: #{Payment.joins(:order).where(orders: { tenant_id: tenant.id }).count}"
    puts "  ✅ OrderStatusLogs: #{OrderStatusLog.where(tenant_id: tenant.id).count}"
    
    puts "\n🔑 Данные для входа:"
    puts "  Email: barista@test.com"
    puts "  Password: test123456"
    puts "\n🎉 Все данные созданы успешно!"
  end
  
  desc "Clean all barista test data"
  task clean_barista_data: :environment do
    puts "🧹 Очистка тестовых данных..."
    
    tenant = Tenant.find_by(name: 'Тестовая кофейня')
    if tenant
      Current.tenant_id = tenant.id
      
      # Delete in correct order (respecting foreign keys)
      Order.where(tenant_id: tenant.id).find_each do |order|
        OrderItem.where(order_id: order.id).delete_all
        Payment.where(order_id: order.id).delete_all
        OrderStatusLog.where(order_id: order.id).delete_all
        order.destroy
      end
      
      CashShift.where(tenant_id: tenant.id).find_each do |shift|
        ShiftStaff.where(cash_shift_id: shift.id).delete_all
        shift.destroy
      end
      
      ProductTenantSetting.where(tenant_id: tenant.id).delete_all
      
      puts "✅ Данные очищены!"
      puts "  - Orders: удалены"
      puts "  - CashShifts: удалены"
      puts "  - ProductTenantSettings: удалены"
      puts "\n⚠️  Products, Categories, Tenant и User сохранены"
    else
      puts "⚠️  Тестовый tenant не найден"
    end
  end
end
