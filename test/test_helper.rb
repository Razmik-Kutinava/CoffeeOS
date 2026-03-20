ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "securerandom"
require_relative "support/factories"

module ActiveSupport
  class TestCase
    # Parallel tests (Rails 8.1+): только :processes и :threads (символ :fork не поддерживается).
    # На Unix используем :processes (отдельные процессы через Parallelization — безопаснее для pg/libvips,
    # чем :threads в одном процессе).
    # Thread-based parallelization может давать "free(): invalid size" (WSL + /mnt/c, нативные гемы).
    #
    # MRI Windows: нет Process.fork — параллель в потоках часто роняет процесс (heap corruption);
    # оставляем последовательный прогон.
    #
    # Sequential: PARALLEL_WORKERS=0  (or false / no)
    # Fixed count: PARALLEL_WORKERS=4 (где есть процессы, или явно 0)
    case ENV["PARALLEL_WORKERS"]&.downcase
    when "0", "false", "no"
      # no parallelize — single process
    else
      workers =
        if ENV["PARALLEL_WORKERS"].present?
          ENV["PARALLEL_WORKERS"].to_i.clamp(1, 32)
        else
          :number_of_processors
        end

      if Process.respond_to?(:fork)
        parallelize(workers: workers, with: :processes)
      elsif Gem.win_platform?
        # последовательно; не вызываем parallelize(workers: N, with: :threads)
      else
        parallelize(workers: workers, with: :threads)
      end
    end

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
