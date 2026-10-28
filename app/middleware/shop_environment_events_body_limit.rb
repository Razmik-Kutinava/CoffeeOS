# TASK_112: публичный beacon POST /shop/api/environment_events — тело не больше 2 КБ.
# Лимит до Rails: JSON-тело разбирается ещё до before_action (лог params, with_shop_tenant!),
# а при Transfer-Encoding Rails читает его целиком. Здесь читаем не больше лимита+1.
class ShopEnvironmentEventsBodyLimit
  PATH = %r{\A/shop/api/environment_events(?:\.\w+)?/?\z}
  MAX_BODY_BYTES = 2048

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless env["REQUEST_METHOD"] == "POST" && PATH.match?(env["PATH_INFO"].to_s)
    return too_large if env["CONTENT_LENGTH"].to_i > MAX_BODY_BYTES

    input = env["rack.input"]
    if input
      probe = input.read(MAX_BODY_BYTES + 1).to_s
      return too_large if probe.bytesize > MAX_BODY_BYTES

      env["rack.input"] = StringIO.new(probe)
      env["CONTENT_LENGTH"] = probe.bytesize.to_s
      env.delete("HTTP_TRANSFER_ENCODING")
    end
    @app.call(env)
  end

  private

  def too_large
    [ 413, { "content-type" => "text/plain" }, [] ]
  end
end
