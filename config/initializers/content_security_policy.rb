Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    # Hotwire/Turbo требует unsafe-inline для inline scripts
    policy.script_src  :self, :unsafe_inline
    policy.style_src   :self, :unsafe_inline
    if Rails.env.development?
      # Vite HMR (config/vite.json port 3036)
      policy.connect_src :self, :wss,
                         "ws://127.0.0.1:3036", "ws://localhost:3036",
                         "http://127.0.0.1:3036", "http://localhost:3036"
    else
      policy.connect_src :self, :wss  # Action Cable WebSocket
    end
    policy.frame_ancestors :none
  end
end
