# Test data for barista dashboard
# Run: rails runner db/seeds_test_barista.rb

puts "🧪 Creating test data for barista dashboard..."

# Find or create test tenant
tenant = Tenant.find_or_create_by!(name: 'Тестовая кофейня') do |t|
  t.type = 'sales_point'
  t.is_active = true
end

Current.tenant_id = tenant.id
puts "✅ Tenant: #{tenant.name}"

# Find or create test barista user
barista = User.find_or_initialize_by(email: 'barista@test.com')
barista.name = 'Бариста Тест'
barista.phone = '+79991234567'
barista.tenant_id = tenant.id
barista.status = 'active'
barista.password = 'password123'
barista.save!

# Ensure barista has barista role
barista_role = Role.find_or_create_by!(code: 'barista') do |r|
  r.name = 'Бариста'
  r.description = 'Бариста'
end

unless barista.roles.include?(barista_role)
  UserRole.create!(user: barista, role: barista_role, tenant_id: tenant.id)
end

puts "✅ Barista user: #{barista.name} (#{barista.email})"
puts "   Password hash: #{barista.password_hash[0..20]}..."

# Create categories
categories = []
['Кофе', 'Чай', 'Еда', 'Десерты'].each_with_index do |cat_name, idx|
  category = Category.find_or_create_by!(slug: cat_name.downcase) do |c|
    c.name = cat_name
    c.sort_order = idx + 1
    c.is_active = true
  end
  categories << category
  puts "✅ Category: #{category.name}"
end

# Create products
products_data = [
  { name: 'Капучино М', category: 'Кофе', price: 350 },
  { name: 'Капучино L', category: 'Кофе', price: 400 },
  { name: 'Латте М', category: 'Кофе', price: 350 },
  { name: 'Латте L', category: 'Кофе', price: 400 },
  { name: 'Американо M', category: 'Кофе', price: 250 },
  { name: 'Эспрессо', category: 'Кофе', price: 200 },
  { name: 'Флэт Уайт', category: 'Кофе', price: 380 },
  { name: 'Чай зелёный', category: 'Чай', price: 200 },
  { name: 'Чай чёрный', category: 'Чай', price: 200 },
  { name: 'Круассан', category: 'Еда', price: 150 },
  { name: 'Пончик', category: 'Десерты', price: 120 },
  { name: 'Чизкейк', category: 'Десерты', price: 250 }
]

products = []
products_data.each do |prod_data|
  category = categories.find { |c| c.name == prod_data[:category] }
  product = Product.find_or_create_by!(name: prod_data[:name]) do |p|
    p.category_id = category.id
    p.sort_order = products.count + 1
    p.is_active = true
  end
  
  # Create product tenant setting
  setting = ProductTenantSetting.find_or_create_by!(
    product_id: product.id,
    tenant_id: tenant.id
  ) do |s|
    s.price = prod_data[:price]
    s.is_enabled = true
    s.is_sold_out = false
  end
  
  products << product
  puts "✅ Product: #{product.name} (#{setting.price} ₽)"
end

# Create or find open cash shift
cash_shift = CashShift.find_or_create_by!(
  tenant_id: tenant.id,
  status: 'open'
) do |cs|
  cs.opened_at = 2.hours.ago
  cs.opened_by_id = barista.id
  cs.opening_cash = 5000.0
end

puts "✅ Cash Shift: ##{cash_shift.id} (opened at #{cash_shift.opened_at.strftime('%H:%M')})"

# Create shift staff entry for barista
shift_staff = ShiftStaff.find_or_create_by!(
  cash_shift_id: cash_shift.id,
  user_id: barista.id
) do |ss|
  ss.status = 'active'
  ss.joined_at = cash_shift.opened_at
end

# Create orders in different statuses
order_statuses = ['accepted', 'preparing', 'ready']
sources = ['kiosk', 'app', 'manual']

order_statuses.each_with_index do |status, status_idx|
  3.times do |i|
    order = Order.create!(
      tenant_id: tenant.id,
      cash_shift_id: cash_shift.id,
      order_number: "TEST-#{Time.current.strftime('%Y%m%d')}-#{status_idx * 3 + i + 1}",
      status: status,
      source: sources.sample,
      final_amount: rand(300..1000),
      created_at: (status_idx * 10 + i).minutes.ago
    )
    
    # Add order items
    num_items = rand(1..3)
    selected_products = products.sample(num_items)
    
    selected_products.each do |product|
      setting = product.product_tenant_settings.find_by(tenant_id: tenant.id)
      OrderItem.create!(
        order_id: order.id,
        product_id: product.id,
        product_name: product.name,
        quantity: rand(1..2),
        price: setting.price,
        total_price: setting.price * rand(1..2)
      )
    end
    
    # Recalculate final amount
    order.update_column(:final_amount, order.order_items.sum(:total_price))
    
    # Create payment if order is not cancelled
    if status != 'cancelled'
      Payment.create!(
        order_id: order.id,
        tenant_id: tenant.id,
        amount: order.final_amount,
        method: ['card', 'cash', 'sbp'].sample,
        status: 'succeeded',
        processed_at: order.created_at + 1.minute
      )
    end
    
    # Create status log
    OrderStatusLog.create!(
      order_id: order.id,
      tenant_id: tenant.id,
      status_from: 'pending_payment',
      status_to: status,
      changed_by_id: barista.id,
      source: 'barista',
      created_at: order.created_at
    )
    
    puts "✅ Order: #{order.order_number} (#{status})"
  end
end

# Create some closed/cancelled orders for history
5.times do |i|
  status = i < 3 ? 'closed' : 'cancelled'
  order = Order.create!(
    tenant_id: tenant.id,
    cash_shift_id: cash_shift.id,
    order_number: "TEST-#{Time.current.strftime('%Y%m%d')}-HIST-#{i + 1}",
    status: status,
    source: sources.sample,
    final_amount: rand(300..1000),
    created_at: (i + 1).hours.ago
  )
  
  num_items = rand(1..3)
  selected_products = products.sample(num_items)
  
  selected_products.each do |product|
    setting = product.product_tenant_settings.find_by(tenant_id: tenant.id)
    OrderItem.create!(
      order_id: order.id,
      product_id: product.id,
      product_name: product.name,
      quantity: rand(1..2),
      price: setting.price,
      total_price: setting.price * rand(1..2)
    )
  end
  
  order.update_column(:final_amount, order.order_items.sum(:total_price))
  
  if status == 'closed'
    Payment.create!(
      order_id: order.id,
      tenant_id: tenant.id,
      amount: order.final_amount,
      method: ['card', 'cash'].sample,
      status: 'succeeded',
      processed_at: order.created_at + 1.minute
    )
  end
  
  OrderStatusLog.create!(
    order_id: order.id,
    tenant_id: tenant.id,
    status_from: 'accepted',
    status_to: status,
    changed_by_id: barista.id,
    source: 'barista',
    created_at: order.created_at
  )
  
  puts "✅ History Order: #{order.order_number} (#{status})"
end

puts "\n🎉 Test data created successfully!"
puts "\n📊 Summary:"
puts "  - Tenant: #{tenant.name}"
puts "  - Products: #{products.count}"
puts "  - Orders (active): #{Order.where(tenant_id: tenant.id, status: ['accepted', 'preparing', 'ready']).count}"
puts "  - Orders (history): #{Order.where(tenant_id: tenant.id, status: ['closed', 'cancelled']).count}"
puts "  - Cash Shift: ##{cash_shift.id}"
puts "\n🔑 Login credentials:"
puts "  Email: barista@test.com"
puts "  Password: password123"
