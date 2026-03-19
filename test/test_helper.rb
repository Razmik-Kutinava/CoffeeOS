ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "securerandom"
require_relative "support/factories"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Tests run against a fresh local Postgres instance; disable RLS so factories can
    # insert data without needing per-connection GUC bootstrap.
    setup do
      next if defined?(@@rls_disabled) && @@rls_disabled

      begin
        conn = ActiveRecord::Base.connection
        tables = conn.select_values("SELECT relname FROM pg_class WHERE relrowsecurity = true AND relkind = 'r'")
        tables.each do |t|
          conn.execute("ALTER TABLE #{conn.quote_table_name(t)} DISABLE ROW LEVEL SECURITY")
        end
      ensure
        @@rls_disabled = true
      end
    end
  end
end

class ActionDispatch::IntegrationTest
  include TestFactories
end
