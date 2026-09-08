# frozen_string_literal: true

require "net/http"
require "json"

module Shop
  # Upsert guest contact into Brevo Contacts after marketing_consent.
  # Separate from BrevoClient (SMTP/transactional email).
  class CrmContactSync
    class Error < StandardError; end

    CONTACTS_URL = URI("https://api.brevo.com/v3/contacts")

    def self.call!(order:, order_email:)
      new(order: order, order_email: order_email).call!
    end

    # Class method so tests can stub without mocha.
    def self.post_contact!(body)
      api_key = ENV["BREVO_API_KEY"].to_s.strip
      request = Net::HTTP::Post.new(CONTACTS_URL)
      request["api-key"] = api_key
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = body.to_json

      response = Net::HTTP.start(CONTACTS_URL.host, CONTACTS_URL.port, use_ssl: true) do |http|
        http.request(request)
      end

      # 201 create, 204 update (updateEnabled)
      unless response.is_a?(Net::HTTPSuccess) || response.code.to_i == 204
        Rails.logger.error("[Shop::CrmContactSync] Brevo Contacts #{response.code} #{response.body.to_s.truncate(200)}")
        raise Error, "Brevo Contacts #{response.code}"
      end

      return { "id" => nil } if response.body.blank?

      JSON.parse(response.body)
    rescue JSON::ParserError
      { "id" => nil }
    end

    def initialize(order:, order_email:)
      @order = order
      @order_email = order_email
    end

    def call!
      if sync_disabled?
        Rails.logger.info("[Shop::CrmContactSync] CRM_SYNC_ENABLED=0 — skip #{@order_email.email}")
        return :disabled
      end

      if credential.blank?
        Rails.logger.error("[Shop::CrmContactSync] BREVO_API_KEY missing")
        raise Error, "BREVO_API_KEY не задан"
      end

      self.class.post_contact!(contact_payload)
    end

    private

    def sync_disabled?
      ENV["CRM_SYNC_ENABLED"].to_s.strip == "0"
    end

    def credential
      ENV["BREVO_API_KEY"].to_s.strip
    end

    def contact_payload
      attributes = {
        "COFFEEOS_CUSTOMER_ID" => @order.customer_id.to_s,
        "COFFEEOS_ORDER_ID" => @order.id.to_s,
        "COFFEEOS_TENANT_ID" => @order.tenant_id.to_s,
        "MARKETING_CONSENT" => true
      }

      phone = customer_phone
      attributes["SMS"] = phone if phone.present?

      payload = {
        "email" => @order_email.email,
        "updateEnabled" => true,
        "attributes" => attributes
      }

      list_id = ENV["BREVO_CRM_LIST_ID"].to_s.strip
      payload["listIds"] = [ list_id.to_i ] if list_id.present?

      payload
    end

    def customer_phone
      customer = @order.customer
      return if customer.blank?

      customer.try(:phone).presence
    end
  end
end
