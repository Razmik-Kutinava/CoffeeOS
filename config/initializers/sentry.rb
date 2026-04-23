return unless ENV["SENTRY_DSN"].present?

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = Rails.env
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Захватываем только 5% транзакций в dev/staging, 100% в prod при необходимости
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.05").to_f

  # Не шлём личные данные пользователей без явного разрешения
  config.send_default_pii = false

  # Фильтруем чувствительные параметры
  config.before_send = lambda do |event, _hint|
    event.request&.data&.delete("password")
    event.request&.data&.delete("password_confirmation")
    event
  end
end
