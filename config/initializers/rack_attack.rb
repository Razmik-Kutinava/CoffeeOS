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
  
  # Лимит на создание заказов баристой: 30 заказов в минуту с одного IP
  throttle('barista/orders', limit: 30, period: 1.minute) do |req|
    req.ip if req.path == '/barista/orders' && req.post?
  end

  # Лимит на логин: 10 попыток в минуту с одного IP
  throttle('auth/login', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/login' && req.post?
  end

  # Лимит для shop API: 150 запросов в минуту с одного IP
  throttle('shop/api', limit: 150, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/shop/api/')
  end

  # Лимит на создание заказов через shop: 10 заказов в минуту с одного IP
  throttle('shop/orders', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/shop/api/orders' && req.post?
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
    next unless req.is_a?(Hash) && req['rack.attack.match_type']
    if req['rack.attack.match_type'] == :throttle
      Rails.logger.warn(
        "[RateLimit] #{req['rack.attack.matched']} - #{req['rack.attack.matched']} - #{req['rack.attack.matched']&.ip} - #{req['rack.attack.matched']&.path}"
      )
    end
  end
end
