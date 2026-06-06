Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :https, :data, :blob,
                       "https://*.tinkoff.ru", "https://*.tcsbank.ru", "https://*.tbank.ru",
                       "https://*.nspk.ru", "https://*.t-static.ru"
    policy.object_src  :none
    # Hotwire/Turbo + T-Bank integration.js (§2.3 этап 4 iframe)
    policy.script_src  :self, :unsafe_inline,
                       "https://*.tinkoff.ru", "https://*.tcsbank.ru", "https://*.tbank.ru",
                       "https://*.nspk.ru", "https://*.t-static.ru"
    policy.style_src   :self, :unsafe_inline,
                       "https://*.tinkoff.ru", "https://*.tcsbank.ru", "https://*.tbank.ru",
                       "https://*.nspk.ru", "https://*.t-static.ru"
    if Rails.env.development?
      # Vite HMR (config/vite.json port 3036)
      policy.connect_src :self, :wss,
                         "ws://127.0.0.1:3036", "ws://localhost:3036",
                         "http://127.0.0.1:3036", "http://localhost:3036",
                         "https://*.tinkoff.ru", "https://*.tcsbank.ru", "https://*.tbank.ru",
                         "https://*.nspk.ru", "https://*.t-static.ru"
    else
      policy.connect_src :self, :wss,
                         "https://*.tinkoff.ru", "https://*.tcsbank.ru", "https://*.tbank.ru",
                         "https://*.nspk.ru", "https://*.t-static.ru"
    end
    # iframe-форма T-Bank (§2.3 этап 4); frame-src — по доке setup_iframe
    policy.frame_src   :self,
                       "https://*.tinkoff.ru", "https://*.tcsbank.ru", "https://*.tbank.ru"
    policy.frame_ancestors :none
  end
end
