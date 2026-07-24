# frozen_string_literal: true

module Shop
  # Выдача refresh_token (MobileSession) после OTP / при ротации Silent Refresh.
  class MobileSessionIssuer
    TTL = 90.days

    def self.call!(customer_id:)
      new(customer_id: customer_id).call!
    end

    def initialize(customer_id:)
      @customer_id = customer_id
    end

    def call!
      raise ArgumentError, "customer_id required" if @customer_id.blank?

      token = nil
      ActiveRecord::Base.transaction do
        MobileSession.where(customer_id: @customer_id, is_active: true).find_each(&:deactivate!)
        token = SecureRandom.hex(32)
        MobileSession.create!(
          customer_id: @customer_id,
          refresh_token: token,
          is_active: true,
          expires_at: TTL.from_now,
          last_used_at: Time.current
        )
      end
      token
    end
  end
end
