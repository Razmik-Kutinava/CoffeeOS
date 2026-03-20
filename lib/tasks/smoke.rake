# frozen_string_literal: true

# Единая точка «дымовых» проверок: тесты, линтер, безопасность (как в CI).
# Запуск: bin/rails smoke  или  bin/rails smoke:ci

namespace :smoke do
  def smoke_system(cmd)
    puts "\n#{'=' * 60}\n>>> #{cmd}\n#{'=' * 60}\n"
    $stdout.flush
    ok = system(cmd)
    abort("Smoke step failed: #{cmd}") unless ok
  end

  desc "Полный набор Minitest (основная проверка здоровья приложения)"
  task :tests do
    smoke_system("bin/rails test")
  end

  desc "RuboCop (стиль кода)"
  task :lint do
    smoke_system("bin/rubocop -f progress")
  end

  desc "Brakeman (статический анализ безопасности)"
  task :brakeman do
    smoke_system("bin/brakeman --no-pager -q")
  end

  desc "bundler-audit (уязвимости гемов)"
  task :bundler_audit do
    smoke_system("bin/bundler-audit")
  end

  desc "importmap audit (JS через importmap)"
  task :importmap_audit do
    smoke_system("bin/importmap audit")
  end

  desc "Проверка RLS (PostgreSQL + tenant_id; нужна БД и rls:check)"
  task rls: :environment do
    Rake::Task["rls:check"].invoke
  end

  desc "Как в CI: тесты + RuboCop + Brakeman + bundler-audit + importmap audit"
  task ci: %i[tests lint brakeman bundler_audit importmap_audit]

  desc "По умолчанию — только тесты (быстрее всего)"
  task default: :tests
end

desc "Дымовая проверка (по умолчанию: все тесты). См. smoke:ci, smoke:rls"
task smoke: "smoke:default"
