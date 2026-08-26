module Callbacks
  class EmailBouncesController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_signature, only: [ :bounce ]

    def bounce
      email = params[:email].to_s.strip.downcase
      reason = params[:reason] || "unknown"
      order_id = params[:order_id].presence

      return render json: { success: true } if email.blank?

      scope = OrderEmail.where(email: email)
      scope = scope.where(order_id: order_id) if order_id

      updated = 0
      scope.find_each do |order_email|
        order_email.update(status: :bounced, bounce_reason: reason)
        updated += 1
      end

      Rails.logger.info("[EmailBounce] email=#{email} order_id=#{order_id} updated=#{updated} reason=#{reason}")
      render json: { success: true, updated: updated }
    rescue => e
      Rails.logger.error("[EmailBounce] Error processing bounce: #{e.message}")
      render json: { success: false, error: e.message }, status: :bad_request
    end

    private

    def verify_webhook_signature
      secret = ENV["EMAIL_BOUNCE_WEBHOOK_SECRET"].presence || ENV["CALLBACK_SHARED_SECRET"].presence
      if secret.blank?
        if Rails.env.production?
          return render json: { error: "webhook not configured" }, status: :unauthorized
        end
        # test/dev without secret: reject to avoid silent open webhook in staging-like envs
        return render json: { error: "webhook secret missing" }, status: :unauthorized
      end

      provided = request.headers["X-Webhook-Signature"].to_s
      provided = provided.delete_prefix("sha256=")
      if provided.blank?
        return render json: { error: "missing signature" }, status: :unauthorized
      end

      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post.to_s)
      unless provided.bytesize == expected.bytesize &&
          ActiveSupport::SecurityUtils.secure_compare(expected, provided)
        render json: { error: "invalid signature" }, status: :unauthorized
      end
    end
  end
end
