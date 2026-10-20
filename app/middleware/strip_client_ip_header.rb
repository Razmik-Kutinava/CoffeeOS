# Fly proxy передаёт IP клиента только в X-Forwarded-For; Client-IP может прислать
# лишь сам клиент. Если он не совпадает с X-Forwarded-For, ActionDispatch::RemoteIp
# бросает IpSpoofAttackError → 500 на любом пути (RUBY-1R). Стоит до RemoteIp.
class StripClientIpHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    env.delete("HTTP_CLIENT_IP")
    @app.call(env)
  end
end
