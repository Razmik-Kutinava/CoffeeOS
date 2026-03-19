class OrdersChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    
    # Подписка на обновления заказов для текущего тенанта
    stream_from "orders_#{current_user.tenant_id}"
  end
  
  def unsubscribed
    stop_all_streams
  end
  
  private
  
  def current_user
    @current_user ||= begin
      user_id = connection.session[:user_id] if connection.session
      User.find_by(id: user_id) if user_id
    end
  end
end
