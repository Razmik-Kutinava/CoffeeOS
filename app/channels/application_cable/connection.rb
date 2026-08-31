module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Получаем user_id из session (если доступна)
      user_id = request.session[:user_id] if request.session

      if user_id
        user = Rls::GucContext.with_auth_login { User.find_by(id: user_id) }
        return user if user
      end

      # TV board: аутентификация по cookie с device_token (без user login)
      token = request.cookies["tv_device_token"] if request&.cookies
      if token.present?
        device = Devices::TokenResolver.find_active(token: token, device_type: "tv_board")
        return device if device
      end

      # Гость витрины: без user_id — каналы сами проверяют reconnect_token (Shop::GuestOrderChannel).
      nil
    end
  end
end
