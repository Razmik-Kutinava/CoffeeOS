# frozen_string_literal: true

module Shop
  # Публичный Firebase config для витрины + серверный service account (FCM HTTP v1).
  class FirebaseConfig
    class << self
      def configured?
        client_configured? && service_account.present?
      end

      def client_configured?
        project_id.present? && api_key.present? && app_id.present? && messaging_sender_id.present?
      end

      def client_json
        {
          apiKey: api_key,
          authDomain: auth_domain,
          projectId: project_id,
          storageBucket: storage_bucket,
          messagingSenderId: messaging_sender_id,
          appId: app_id,
          vapidKey: vapid_key
        }.compact
      end

      def project_id
        ENV["FIREBASE_PROJECT_ID"].presence || service_account&.dig("project_id")
      end

      def api_key
        ENV["FIREBASE_API_KEY"].presence
      end

      def auth_domain
        ENV["FIREBASE_AUTH_DOMAIN"].presence
      end

      def storage_bucket
        ENV["FIREBASE_STORAGE_BUCKET"].presence
      end

      def messaging_sender_id
        ENV["FIREBASE_MESSAGING_SENDER_ID"].presence
      end

      def app_id
        ENV["FIREBASE_APP_ID"].presence
      end

      def vapid_key
        ENV["FIREBASE_VAPID_KEY"].presence
      end

      def service_account
        return @service_account if defined?(@service_account)

        raw = ENV["FIREBASE_SERVICE_ACCOUNT_JSON"].to_s.strip
        @service_account =
          if raw.blank?
            nil
          else
            JSON.parse(raw)
          end
      rescue JSON::ParserError
        @service_account = nil
      end

      def reset_cache!
        remove_instance_variable(:@service_account) if instance_variable_defined?(:@service_account)
      end
    end
  end
end
