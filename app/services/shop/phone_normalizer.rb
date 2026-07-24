# frozen_string_literal: true

module Shop
  # Приводит российский мобильный к канону +79XXXXXXXXX.
  class PhoneNormalizer
    class Error < StandardError; end

    def self.normalize!(phone)
      new.normalize!(phone)
    end

    def normalize!(phone)
      digits = phone.to_s.gsub(/\D/, "")
      raise Error, "Укажите корректный номер телефона" if digits.blank?

      digits = "7#{digits[1..]}" if digits.length == 11 && digits.start_with?("8")
      digits = "7#{digits}" if digits.length == 10 && digits.start_with?("9")

      unless digits.match?(/\A7\d{10}\z/)
        raise Error, "Укажите корректный номер телефона"
      end

      "+#{digits}"
    end
  end
end
