module Callbacks
  class EmailBouncesController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_signature, only: [ :bounce ]

    def bounce
      email = params[:email]
      reason = params[:reason] || "unknown"

      return render json: { success: true } if email.blank?

      order_email = OrderEmail.find_by(email: email)
      if order_email
        order_email.update(status: :bounced, bounce_reason: reason)
        Rails.logger.info("[EmailBounce] Email #{email} marked as bounced: #{reason}")
      end

      render json: { success: true }
    rescue => e
      Rails.logger.error("[EmailBounce] Error processing bounce: #{e.message}")
      render json: { success: false, error: e.message }, status: :bad_request
    end

    private

    def verify_webhook_signature
      # Webhook signature verification will be implemented when email provider is selected
      # Expected signature header: X-Webhook-Signature
      # Expected format: HMAC-SHA256(webhook_secret, request_body)
      true
    end
  end
end
