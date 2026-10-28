require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoffeeOs
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Автозагрузка middleware
    config.autoload_paths << Rails.root.join("app/middleware")

    require_relative "../app/middleware/strip_client_ip_header"
    config.middleware.insert_before ActionDispatch::RemoteIp, StripClientIpHeader

    require_relative "../app/middleware/shop_environment_events_body_limit"
    config.middleware.insert_before ActionDispatch::RemoteIp, ShopEnvironmentEventsBodyLimit

    # Лог каждого запроса в JSON (шумно). Включить: LOG_TENANT_MIDDLEWARE=1
    if ENV["LOG_TENANT_MIDDLEWARE"].present?
      require_relative "../app/middleware/log_tenant_middleware"
      config.middleware.use LogTenantMiddleware
    end
  end
end
