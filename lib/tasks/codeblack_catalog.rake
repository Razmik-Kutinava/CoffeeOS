# frozen_string_literal: true

# Обратная совместимость: старое имя задачи. Предпочтительно: bin/rails catalog:replace

namespace :codeblack do
  desc "Deprecated: используйте catalog:replace"
  task replace_catalog: :environment do
    warn "[DEPRECATED] Используйте bin/rails catalog:replace (вместо codeblack:replace_catalog)."
    Rake::Task["catalog:replace"].invoke
  end
end
