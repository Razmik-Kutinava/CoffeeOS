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

    unless ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_AUTO_SEED", "false"))
      puts "[fly:release] DEMO_AUTO_SEED not set — skip demo:seed"
      next
    end

    puts "[fly:release] demo:seed..."
    Rake::Task["demo:seed"].invoke
    puts "[fly:release] OK"
  end
end
