# frozen_string_literal: true

module Analytics
  # Считает заказы за последние WINDOW_MINUTES по orders.source для каждой
  # активной sales_point и пишет одну JSON-строку в лог на tenant.
  # Временный сбор (1–2 недели); Telegram не трогает.
  class ChannelOrderStatsCollector
    WINDOW_MINUTES = 15
    SOURCES = %w[mobile manual kiosk app].freeze
    LOG_TAG = "ChannelOrderStats"

    Result = Struct.new(:tenants_logged, :window_minutes, keyword_init: true)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(now: Time.current, window_minutes: WINDOW_MINUTES)
      @now = now
      @window_minutes = window_minutes
      @since = now - window_minutes.minutes
    end

    def call
      logged = 0

      Tenant.where(status: "active", type: "sales_point").find_each do |tenant|
        log_tenant!(tenant)
        logged += 1
      end

      Result.new(tenants_logged: logged, window_minutes: window_minutes)
    end

    private

    attr_reader :now, :window_minutes, :since

    def log_tenant!(tenant)
      counts = counts_for(tenant)
      open_now = TenantOperatingHours.open_now?(tenant, at: now)

      payload = {
        event: LOG_TAG,
        measured_at: now.iso8601,
        tenant_id: tenant.id,
        tenant_slug: tenant.slug,
        window_minutes: window_minutes,
        since: since.iso8601,
        open_now: open_now,
        counts: SOURCES.index_with { |source| counts[source].to_i }
      }

      Rails.logger.info("[#{LOG_TAG}] #{payload.to_json}")
    end

    def counts_for(tenant)
      ActiveRecord::Base.transaction do
        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")

        Order.where(tenant_id: tenant.id)
             .where("created_at >= ? AND created_at < ?", since, now)
             .group(:source)
             .count
      end
    end
  end
end
