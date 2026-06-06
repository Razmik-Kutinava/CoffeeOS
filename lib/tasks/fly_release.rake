# frozen_string_literal: true

module FlyRelease
  module_function

  def load_solid_schema!(db_name, schema_path, marker_table:)
    cfg = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: db_name)
    return unless cfg

    path = Rails.root.join(schema_path)
    return unless path.exist?

    conn_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
    conn_class.establish_connection(cfg.configuration_hash)

    if conn_class.connection.table_exists?(marker_table)
      puts "[fly:release] #{marker_table} exists (#{db_name}) — skip load_schema"
      return
    end

    puts "[fly:release] load schema #{schema_path} (#{db_name})..."
    ActiveRecord::Tasks::DatabaseTasks.load_schema(cfg, ActiveRecord.schema_format, path)
  rescue StandardError => e
    puts "[fly:release] WARN schema #{db_name}: #{e.class} #{e.message}"
  end
end

namespace :fly do
  desc "Fly release: db:prepare + solid migrations + demo:seed (DEMO_AUTO_SEED=true)"
  task release: :environment do
    puts "[fly:release] db:prepare..."
    Rake::Task["db:prepare"].invoke

    puts "[fly:release] db:ensure_triggers..."
    Rake::Task["db:ensure_triggers"].invoke

    Payments::CacheCounter.clear_circuit!
    puts "[fly:release] cleared T-Bank circuit breaker cache"

    FlyRelease.load_solid_schema!("queue", "db/queue_schema.rb", marker_table: "solid_queue_jobs")
    FlyRelease.load_solid_schema!("cache", "db/cache_schema.rb", marker_table: "solid_cache_entries")
    FlyRelease.load_solid_schema!("cable", "db/cable_schema.rb", marker_table: "solid_cable_messages")

    %w[queue cache cable].each do |db|
      name = "db:migrate:#{db}"
      next unless Rake::Task.task_defined?(name)

      puts "[fly:release] #{name}..."
      Rake::Task[name].invoke
    end

    if ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_AUTO_SEED", "false"))
      puts "[fly:release] demo:seed..."
      Rake::Task["demo:seed"].invoke
    else
      puts "[fly:release] DEMO_AUTO_SEED not set — skip demo:seed"
    end

    puts "[fly:release] OK"
  end

  desc "Prod smoke: card order + signed T-Bank CONFIRMED webhook via Solid Queue worker"
  task callback_smoke: :environment do
    require "net/http"

    tenant_id  = ENV.fetch("SMOKE_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
    product_id = ENV.fetch("SMOKE_PRODUCT_ID", "24dae391-2199-4959-907e-d08c4cec3329")

    tenant = Tenant.find(tenant_id)
    session = {}
    Shop::CartService.new(session, tenant.id).add!(
      product_id: product_id,
      quantity: 1,
      selected_modifiers: []
    )

    order = Shop::OrderCreator.new(session, tenant: tenant).call!(
      name: "WorkerCallbackSmoke",
      phone: "+7900#{SecureRandom.random_number(10**7).to_s.rjust(7, '0')}",
      payment_method: "card"
    )
    raise "expected pending_payment, got #{order.status}" unless order.pending_payment?

    payment = order.payments.order(created_at: :desc).first
    payment_id = payment.provider_payment_id.presence || "smoke-#{SecureRandom.hex(4)}"
    payment.update!(provider: "tbank", provider_payment_id: payment_id) if payment.provider_payment_id.blank?

    payload = {
      "TerminalKey" => ENV.fetch("TBANK_TERMINAL_KEY"),
      "OrderId"     => order.id.to_s,
      "PaymentId"   => payment_id,
      "Status"      => "CONFIRMED",
      "Amount"      => (order.final_amount * 100).to_i
    }
    payload["Token"] = Payments::TbankAdapter.new.build_token(payload)

    host = ENV.fetch("APP_HOST", "coffeeos.fly.dev")
    res = Net::HTTP.post(
      URI("https://#{host}/callbacks/tbank"),
      payload.to_json,
      "Content-Type" => "application/json"
    )

    sleep 5
    order.reload
    payment.reload

    puts({
      smoke: "worker_callback",
      order_id: order.id,
      order_status: order.status,
      payment_status: payment.status,
      callback_http: res.code,
      callback_body: res.body
    }.to_json)
  end

  desc "Prod smoke §2.3 stage 5.2: card order → webhook → history today"
  task stage5_2_smoke: :environment do
    require "net/http"

    tenant_id  = ENV.fetch("SMOKE_TENANT_ID", "2fdee1ac-4674-41ee-b89e-87b45643f789")
    product_id = ENV.fetch("SMOKE_PRODUCT_ID", "24dae391-2199-4959-907e-d08c4cec3329")
    tenant = Tenant.find(tenant_id)
    phone = "+7906#{SecureRandom.random_number(10**7).to_s.rjust(7, '0')}"
    session = {}

    Shop::CartService.new(session, tenant.id).add!(
      product_id: product_id,
      quantity: 1,
      selected_modifiers: []
    )

    order = Shop::OrderCreator.new(session, tenant: tenant).call!(
      name: "Stage52Smoke",
      phone: phone,
      payment_method: "card"
    )
    raise "expected pending_payment, got #{order.status}" unless order.pending_payment?

    payment = order.payments.order(created_at: :desc).first
    payment_id = payment.provider_payment_id.presence || "smoke-#{SecureRandom.hex(4)}"
    payment.update!(provider: "tbank", provider_payment_id: payment_id) if payment.provider_payment_id.blank?

    payload = {
      "TerminalKey" => ENV.fetch("TBANK_TERMINAL_KEY"),
      "OrderId"     => order.id.to_s,
      "PaymentId"   => payment_id,
      "Status"      => "CONFIRMED",
      "Amount"      => (order.final_amount * 100).to_i
    }
    payload["Token"] = Payments::TbankAdapter.new.build_token(payload)

    host = ENV.fetch("APP_HOST", "coffeeos.fly.dev")
    res = Net::HTTP.post(
      URI("https://#{host}/callbacks/tbank"),
      payload.to_json,
      "Content-Type" => "application/json"
    )
    sleep 5
    order.reload

    payment_settled = order.accepted?
    if payment_settled
      Shop::CartService.new(session, tenant.id).clear!
      Shop::PendingOrderSession.clear!(session, tenant.id)
    end

    cid = Shop::CustomerSession.customer_id(session, tenant.id)
    history = if cid.present?
      Order.where(tenant_id: tenant.id, customer_id: cid, source: :mobile)
        .where("orders.created_at >= ?", Time.zone.today.beginning_of_day)
        .order(created_at: :desc)
        .includes(:order_items)
        .map do |o|
          {
            "id" => o.id,
            "status" => o.status,
            "total" => o.final_amount.to_f,
            "items_count" => o.order_items.size
          }
        end
    else
      []
    end
    row = history.find { |r| r["id"] == order.id }

    puts({
      smoke: "stage5_2_history",
      order_id: order.id,
      order_status: order.status,
      customer_bound: cid.present?,
      payment_settled: payment_settled,
      history_count: history.size,
      history_found: row.present?,
      history_status: row&.dig("status"),
      history_total: row&.dig("total"),
      callback_http: res.code
    }.to_json)
  end
end
