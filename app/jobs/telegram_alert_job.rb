# Job для отправки алертов в Telegram
class TelegramAlertJob < ApplicationJob
  queue_as :default
  
  def perform(message, context = {})
    return unless ENV['TELEGRAM_BOT_TOKEN'] && ENV['TELEGRAM_CHAT_ID']
    
    text = "🚨 *CoffeeOS Alert*\n\n#{message}"
    
    if context.any?
      text += "\n\n*Context:*\n"
      context.each do |key, value|
        text += "#{key}: #{value}\n"
      end
    end
    
    HTTParty.post(
      "https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendMessage",
      body: {
        chat_id: ENV['TELEGRAM_CHAT_ID'],
        text: text,
        parse_mode: 'Markdown'
      }
    )
  end
end
