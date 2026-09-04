# frozen_string_literal: true

module Shop
  class PushRegistrationService
    class Error < StandardError; end

    def self.call(customer:, push_token:, push_enabled: true)
      new(customer: customer, push_token: push_token, push_enabled: push_enabled).call!
    end

    def initialize(customer:, push_token:, push_enabled: true)
      @customer = customer
      @push_token = push_token
      @push_enabled = push_enabled
    end

    def call!
      raise Error, "Клиент не найден" unless @customer

      if @push_enabled
        token = @push_token.to_s.strip
        raise Error, "push_token обязателен" if token.blank?

        @customer.update!(push_enabled: true, push_token: token)
        @customer.mark_push_enabled!
      else
        @customer.update!(push_enabled: false)
      end

      @customer
    end
  end
end
