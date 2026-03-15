# Rate limiting для API
# Защита от злоупотреблений и DDoS

class Rack::Attack
  # Лимит для API: 100 запросов в минуту с одного IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end
  
  # Лимит для киоска: 10 запросов в секунду по device_token
  throttle('kiosk/device', limit: 10, period: 1.second) do |req|
    req.env['HTTP_X_DEVICE_TOKEN'] if req.path.start_with?('/api/kiosk/')
  end
  
  # Лимит для мобильного API: 200 запросов в минуту по refresh_token
  throttle('mobile/api', limit: 200, period: 1.minute) do |req|
    if req.path.start_with?('/api/mobile/')
      # Извлекаем refresh_token из заголовка
      req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    end
  end
  
  # Лимит для OTP: 5 запросов в минуту с одного телефона
  throttle('otp/phone', limit: 5, period: 1.minute) do |req|
    if req.path == '/api/mobile/otp/send'
      JSON.parse(req.body.read)['phone'] rescue nil
    end
  end
  
  # Блокировка при превышении лимита
  self.throttled_responder = lambda do |env|
    [
      429,
      { 'Content-Type' => 'application/json', 'Retry-After' => '60' },
      [{ error: { code: 'RATE_LIMIT_EXCEEDED', retry_after: 60 } }.to_json]
    ]
  end
  
  # Логирование заблокированных запросов
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
    if req.env['rack.attack.match_type'] == :throttle
      Rails.logger.warn(
        "[RateLimit] #{req.env['rack.attack.matched']} - #{req.ip} - #{req.path}"
      )
    end
  end
end
