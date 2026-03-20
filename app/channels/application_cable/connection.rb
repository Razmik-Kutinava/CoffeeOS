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
        device = nil
        ActiveRecord::Base.connection.transaction do
          ActiveRecord::Base.connection.execute("SET LOCAL row_security = off")
          return User.find_by(id: user_id)
        end
      end

      # TV board: аутентификация по cookie с device_token (без user login)
      token = request.cookies["tv_device_token"] if request&.cookies
      if token.present?
        ActiveRecord::Base.connection.transaction do
          ActiveRecord::Base.connection.execute("SET LOCAL row_security = off")
          device = Device.active.find_by(device_token: token, device_type: 'tv_board')
          return nil if device&.token_valid?
        end
      end

      reject_unauthorized_connection
    end
  end
end
