# Middleware для автоматического логирования Current.tenant_id
# Помогает в troubleshooting RLS проблем
# Использует структурированное JSON логирование для лучшего парсинга
class LogTenantMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    start_time = Time.current
    
    # Логировать начало запроса
    Rails.logger.info({
      event: 'request_started',
      request_id: env['action_dispatch.request_id'],
      tenant_id: Current.tenant_id,
      user_id: Current.user_id,
      path: request.path,
      method: request.request_method,
      ip: request.ip
    }.to_json)
    
    status, headers, response = @app.call(env)
    
    # Логировать завершение запроса
    duration = ((Time.current - start_time) * 1000).round(2) # в миллисекундах
    Rails.logger.info({
      event: 'request_completed',
      request_id: env['action_dispatch.request_id'],
      status: status,
      duration_ms: duration,
      tenant_id: Current.tenant_id
    }.to_json)
    
    [status, headers, response]
  rescue => e
    # Логировать ошибку
    Rails.logger.error({
      event: 'request_error',
      request_id: env['action_dispatch.request_id'],
      error: e.class.name,
      message: e.message,
      tenant_id: Current.tenant_id,
      path: env['PATH_INFO']
    }.to_json)
    raise
  ensure
    # Предупреждение для API запросов без tenant_id
    if !Current.tenant_id && env['PATH_INFO'].start_with?('/api/')
      Rails.logger.warn({
        event: 'missing_tenant_id',
        request_id: env['action_dispatch.request_id'],
        path: env['PATH_INFO'],
        method: env['REQUEST_METHOD']
      }.to_json)
    end
  end
end
