# frozen_string_literal: true

namespace :fly do
  desc "Fly release: db:prepare + solid migrations + demo:seed (DEMO_AUTO_SEED=true)"
  task release: :environment do
    puts "[fly:release] db:prepare..."
    Rake::Task["db:prepare"].invoke

    puts "[fly:release] db:ensure_triggers..."
    Rake::Task["db:ensure_triggers"].invoke

    Payments::CacheCounter.delete(Payments::TbankAdapter::CB_FAILURES_KEY)
    Rails.cache.delete(Payments::TbankAdapter::CB_OPEN_KEY)
    puts "[fly:release] cleared T-Bank circuit breaker cache"

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
