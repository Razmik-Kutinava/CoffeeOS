namespace :tenant do
  desc "Run task with tenant context (wrapper)"
  task :with_context, [:tenant_id, :task_name] => :environment do |t, args|
    tenant_id = args[:tenant_id]
    task_name = args[:task_name]
    
    if tenant_id.blank? || task_name.blank?
      puts "Usage: rails tenant:with_context[tenant-uuid,task:name]"
      exit 1
    end
    
    tenant = Tenant.find(tenant_id)
    
    # Устанавливаем контекст
    Current.tenant_id = tenant.id
    ActiveRecord::Base.connection.execute(
      "SET LOCAL app.current_tenant_id = '#{tenant.id}'"
    )
    
    puts "🔧 Running task '#{task_name}' for tenant: #{tenant.name}"
    
    begin
      # Запускаем задачу
      Rake::Task[task_name].invoke
    ensure
      # Очищаем контекст
      Current.reset
      ActiveRecord::Base.connection.execute("RESET app.current_tenant_id")
    end
  end
  
  desc "Generate daily report for tenant"
  task :daily_report, [:tenant_id] => :environment do |t, args|
    tenant_id = args[:tenant_id]
    
    if tenant_id.blank?
      puts "Usage: rails tenant:daily_report[tenant-uuid]"
      exit 1
    end
    
    tenant = Tenant.find(tenant_id)
    
    # Устанавливаем контекст
    Current.tenant_id = tenant.id
    ActiveRecord::Base.connection.execute(
      "SET LOCAL app.current_tenant_id = '#{tenant.id}'"
    )
    
    puts "📊 Generating daily report for #{tenant.name}..."
    
    # Логика отчёта
    orders_count = Order.where(created_at: Date.today.all_day).count
    revenue = Payment.where(
      created_at: Date.today.all_day,
      status: 'succeeded'
    ).sum(:amount)
    
    puts "Orders today: #{orders_count}"
    puts "Revenue today: #{revenue} RUB"
    
  ensure
    Current.tenant_id = nil
    ActiveRecord::Base.connection.execute("RESET app.current_tenant_id")
  end
end
