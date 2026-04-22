Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    # Hotwire/Turbo требует unsafe-inline для inline scripts
    policy.script_src  :self, :unsafe_inline
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self, :wss  # Action Cable WebSocket
    policy.frame_ancestors :none
  end
end
