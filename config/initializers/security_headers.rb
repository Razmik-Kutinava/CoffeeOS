Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Content-Type-Options" => "nosniff",
  "X-Frame-Options"        => "DENY",
  "Referrer-Policy"        => "strict-origin-when-cross-origin",
  "Permissions-Policy"     => "camera=(), microphone=(), geolocation=()"
)

# HSTS добавляется только в production — в dev/test HTTPS не обязателен
Rails.application.config.force_ssl = true if Rails.env.production?
