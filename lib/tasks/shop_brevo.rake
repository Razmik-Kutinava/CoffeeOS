# frozen_string_literal: true

namespace :shop do
  namespace :brevo do
    desc "Проверка Brevo: отправка тестового OTP на MAIL_FROM"
    task test: :environment do
      to = ENV["MAIL_FROM"].to_s.strip
      abort "Задайте MAIL_FROM в .env" if to.blank?

      key = ENV["BREVO_API_KEY"].to_s.strip
      mode = key.start_with?("xsmtpsib") ? "SMTP" : "API"
      puts "Режим: #{mode}, ключ: #{key.present? ? 'задан' : 'нет'}"

      Shop::BrevoClient.deliver_otp!(to: to, code: "000000")
      puts "OK — письмо отправлено на #{to}"
    rescue Shop::BrevoClient::Error => e
      abort "FAIL: #{e.message}"
    end
  end
end
