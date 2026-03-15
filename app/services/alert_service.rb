# Сервис для отправки алертов (email, Telegram)
class AlertService
  # Критичные алерты (email + Telegram)
  def self.critical(message:, context: {})
    # Email админам
    AdminUser.where(receive_alerts: true).each do |admin|
      AdminMailer.critical_alert(
        admin,
        message: message,
        context: context
      ).deliver_later
    end
    
    # Telegram (если настроен)
    if ENV['TELEGRAM_BOT_TOKEN'] && ENV['TELEGRAM_CHAT_ID']
      TelegramAlertJob.perform_later(message, context)
    end
    
    # Логирование
    Rails.logger.error("[ALERT] CRITICAL: #{message}", context)
  end
  
  # Предупреждения (только email)
  def self.warning(message:, context: {})
    AdminUser.where(receive_alerts: true).each do |admin|
      AdminMailer.warning_alert(
        admin,
        message: message,
        context: context
      ).deliver_later
    end
    
    Rails.logger.warn("[ALERT] WARNING: #{message}", context)
  end
  
  # Информационные сообщения (только логи)
  def self.info(message:, context: {})
    Rails.logger.info("[ALERT] INFO: #{message}", context)
  end
end
