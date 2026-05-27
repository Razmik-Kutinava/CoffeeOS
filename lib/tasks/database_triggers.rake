# frozen_string_literal: true

namespace :db do
  desc "Ensure PostgreSQL triggers missing from schema.rb (order_number, etc.)"
  task ensure_triggers: :environment do
    DatabaseTriggers.ensure_order_number!
    puts "[db:ensure_triggers] order_number trigger OK"
  end
end
