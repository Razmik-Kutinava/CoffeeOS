# frozen_string_literal: true

# После db:schema:load триггеры отсутствуют — восстанавливаем в dev/test при boot.
if Rails.env.local?
  Rails.application.config.after_initialize do
    DatabaseTriggers.ensure_all!
  rescue StandardError => e
    Rails.logger.warn("DatabaseTriggers.ensure_all! skipped: #{e.class} — #{e.message}")
  end
end
