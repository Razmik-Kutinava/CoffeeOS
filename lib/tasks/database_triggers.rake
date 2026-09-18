# frozen_string_literal: true

namespace :db do
  desc "Ensure PostgreSQL triggers missing from schema.rb (order_number, auto_deduct, stop_list)"
  task ensure_triggers: :environment do
    DatabaseTriggers.ensure_all!
    puts "[db:ensure_triggers] ensure_all! OK (order_number + auto_deduct + stop_list)"
  end
end
