# frozen_string_literal: true

module Shop
  # TASK_112: нормализует снимок окружения из тела запроса и сохраняет его.
  # Точка — только аргумент (серверный tenant resolution); ключи вне белого списка не читаются,
  # неверные значения → unavailable / other / other_inapp, неизвестный event_kind → отказ.
  class EnvironmentEventRecorder
    Result = Data.define(:event, :error) do
      def ok? = error.nil?
    end

    DEFAULT_EVENT_KIND = "session_open"
    FLAG_COLUMNS = {
      "standalone" => ShopEnvironmentEvent::STANDALONE_STATES,
      "notification_state" => ShopEnvironmentEvent::NOTIFICATION_STATES,
      "push_manager" => ShopEnvironmentEvent::AVAILABILITY,
      "service_worker" => ShopEnvironmentEvent::AVAILABILITY,
      "storage_local" => ShopEnvironmentEvent::AVAILABILITY,
      "storage_session" => ShopEnvironmentEvent::AVAILABILITY
    }.freeze

    def self.call(point_id:, payload:)
      new(point_id: point_id, payload: payload).call
    end

    def initialize(point_id:, payload:)
      @point_id = point_id
      @payload = payload.is_a?(Hash) ? payload.stringify_keys : {}
    end

    def call
      return Result.new(event: nil, error: :point_missing) if @point_id.blank?

      kind = event_kind
      return Result.new(event: nil, error: :unknown_event_kind) unless ShopEnvironmentEvent::EVENT_KINDS.include?(kind)

      label = pick(@payload["inapp_label"], ShopEnvironmentEvent::INAPP_LABELS, "other_inapp")
      attrs = {
        point_id: @point_id,
        event_kind: kind,
        os_family: pick(@payload["os_family"], ShopEnvironmentEvent::OS_FAMILIES, "other"),
        inapp_label: label,
        ua_snippet: ua_snippet(label)
      }
      FLAG_COLUMNS.each { |column, allowed| attrs[column.to_sym] = pick(@payload[column], allowed, "unavailable") }

      Result.new(event: ShopEnvironmentEvent.create!(attrs), error: nil)
    end

    private

    def event_kind
      raw = @payload["event_kind"]
      return DEFAULT_EVENT_KIND if raw.nil? || raw == ""

      raw.is_a?(String) ? raw : ""
    end

    def pick(value, allowed, fallback)
      value.is_a?(String) && allowed.include?(value) ? value : fallback
    end

    def ua_snippet(label)
      return nil unless label == "other_inapp"

      raw = @payload["ua_snippet"]
      return nil unless raw.is_a?(String) && raw.present?

      raw.last(ShopEnvironmentEvent::UA_SNIPPET_MAX)
    end
  end
end
