# Rate limiting для API
# Защита от злоупотреблений и DDoS

class Rack::Attack
  SHOP_PHONE_OTP_RETRY_AFTER = {
    "shop/phone_otp_callcheck" => 20,
    "shop/phone_otp_sms" => 60
  }.freeze

  # Используем MemoryStore для rate limiting, так как SolidCache не поддерживает increment
  # Это предотвращает ошибки при upsert в solid_cache_entries
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Лимит для API: 100 запросов в минуту с одного IP
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Лимит для киоска: 10 запросов в секунду по device_token
  throttle("kiosk/device", limit: 10, period: 1.second) do |req|
    req.env["HTTP_X_DEVICE_TOKEN"] if req.path.start_with?("/kiosk/api/")
  end

  throttle("kiosk/auth/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/kiosk/api/auth" && req.post?
  end

  # Лимит для мобильного API: 200 запросов в минуту по refresh_token
  throttle("mobile/api", limit: 200, period: 1.minute) do |req|
    if req.path.start_with?("/api/mobile/")
      # Извлекаем refresh_token из заголовка
      req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
    end
  end

  # Лимит для OTP: 5 запросов в минуту с одного телефона
  throttle("otp/phone", limit: 5, period: 1.minute) do |req|
    if req.path == "/api/mobile/otp/send"
      JSON.parse(req.body.read)["phone"] rescue nil
    end
  end

  # Лимит OTP витрины: 5 писем в минуту на email
  throttle("shop/email_otp", limit: 5, period: 1.minute) do |req|
    if req.path == "/shop/api/email_otp/send" && req.post?
      body = req.body.read
      req.body.rewind if req.body.respond_to?(:rewind)
      JSON.parse(body)["email"].to_s.downcase.presence rescue nil
    end
  end

  # Callcheck init: 1 / 20s на телефон. SMS fallback: 1 / 60s.
  throttle("shop/phone_otp_callcheck", limit: 1, period: 20.seconds) do |req|
    Rack::Attack.shop_phone_otp_phone_from_path(req, "/shop/api/phone_otp/init_callcheck")
  end

  throttle("shop/phone_otp_sms", limit: 1, period: 60.seconds) do |req|
    Rack::Attack.shop_phone_otp_phone_from_path(req, "/shop/api/phone_otp/send_sms") ||
      Rack::Attack.shop_phone_otp_legacy_sms(req)
  end

  # Лимит на создание заказов баристой: 30 заказов в минуту с одного IP
  throttle("barista/orders", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/barista/orders" && req.post?
  end

  # Лимит на логин: 10 попыток в минуту с одного IP
  throttle("auth/login", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # Лимит для shop API: 150 запросов в минуту с одного IP
  throttle("shop/api", limit: 150, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/shop/api/")
  end

  # Лимит на создание заказов через shop: 10 заказов в минуту с одного IP
  throttle("shop/orders", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/shop/api/orders" && req.post?
  end

  # Блокировка при превышении лимита
  self.throttled_responder = lambda do |req|
    matched =
      if req.respond_to?(:env)
        req.env["rack.attack.matched"].to_s
      elsif req.is_a?(Hash)
        req["rack.attack.matched"].to_s
      else
        ""
      end
    retry_after = SHOP_PHONE_OTP_RETRY_AFTER.fetch(matched, 60)
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { error: { code: "RATE_LIMIT_EXCEEDED", retry_after: retry_after } }.to_json ]
    ]
  end

  # Логирование заблокированных запросов
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, req|
    match_type =
      if req.respond_to?(:env)
        req.env["rack.attack.match_type"]
      elsif req.is_a?(Hash)
        req["rack.attack.match_type"]
      end
    next unless match_type

    if match_type == :throttle
      matched =
        if req.respond_to?(:env)
          req.env["rack.attack.matched"]
        elsif req.is_a?(Hash)
          req["rack.attack.matched"]
        end
      Rails.logger.warn(
        "[RateLimit] #{matched} - #{matched} - #{req.respond_to?(:ip) ? req.ip : nil} - #{req.respond_to?(:path) ? req.path : nil}"
      )
    end
  end

  def self.shop_phone_otp_phone_from_path(req, path)
    return unless req.path == path && req.post?

    body = req.body.read
    req.body.rewind if req.body.respond_to?(:rewind)
    json = JSON.parse(body) rescue {}
    phone = json["phone"].to_s.presence
    return unless phone.present?

    "#{phone}:#{path}"
  end

  def self.shop_phone_otp_legacy_sms(req)
    return unless req.path == "/shop/api/phone_otp/send" && req.post?

    body = req.body.read
    req.body.rewind if req.body.respond_to?(:rewind)
    json = JSON.parse(body) rescue {}
    phone = json["phone"].to_s.presence
    return unless phone.present? && json["channel"].to_s == "sms"

    "#{phone}:sms"
  end
end

Rack::Attack.enabled = false if Rails.env.test?
