# frozen_string_literal: true

module Devices
  # Cron-обработка истекающих device_token (IB-P-02).
  # Не ротирует автоматически — иначе kiosk/TV потеряют доступ без процесса в manager.
  # · истёк + active → is_active=false + алерт
  # · скоро истекает (≤ WARN_DAYS) → алерт GM (Telegram), без смены token
  class ExpiringTokensProcessor
    Result = Struct.new(:deactivated, :warned, :skipped_ttl, keyword_init: true)

    METADATA_WARNED_AT = "token_expiry_warned_at"
    METADATA_DEACTIVATED_AT = "token_expiry_deactivated_at"
    METADATA_DEACTIVATED_BY = "token_expiry_deactivated_by"

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(now: Time.current)
      @now = now
      @warn_days = TokenCredentials.rotate_warn_days
    end

    def call
      return Result.new(deactivated: 0, warned: 0, skipped_ttl: true) unless TokenCredentials.ttl_days

      deactivated = 0
      warned = 0

      Tenant.where(status: "active").find_each do |tenant|
        counts = process_tenant(tenant)
        deactivated += counts[:deactivated]
        warned += counts[:warned]
      end

      Result.new(deactivated: deactivated, warned: warned, skipped_ttl: false)
    end

    private

    def process_tenant(tenant)
      deactivated = 0
      warned = 0

      ActiveRecord::Base.transaction do
        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")

        expired_scope(tenant).find_each do |device|
          next unless deactivate_expired!(device, tenant)

          deactivated += 1
        end

        expiring_soon_scope(tenant).find_each do |device|
          next unless warn_expiring!(device, tenant)

          warned += 1
        end
      end

      { deactivated: deactivated, warned: warned }
    end

    def expired_scope(tenant)
      Device.where(tenant_id: tenant.id, is_active: true)
            .where.not(token_expires_at: nil)
            .where("token_expires_at <= ?", @now)
    end

    def expiring_soon_scope(tenant)
      Device.where(tenant_id: tenant.id, is_active: true)
            .where.not(token_expires_at: nil)
            .where("token_expires_at > ?", @now)
            .where("token_expires_at <= ?", @now + @warn_days.days)
    end

    def deactivate_expired!(device, tenant)
      meta = (device.metadata || {}).merge(
        METADATA_DEACTIVATED_AT => @now.iso8601,
        METADATA_DEACTIVATED_BY => "cron"
      )
      device.update!(is_active: false, metadata: meta)

      TelegramAlertJob.perform_later(
        expired_message(device, tenant),
        alert_context(device, tenant, action: "deactivated")
      )
      true
    end

    def warn_expiring!(device, tenant)
      return false unless should_warn?(device)

      meta = (device.metadata || {}).merge(METADATA_WARNED_AT => @now.iso8601)
      device.update!(metadata: meta)

      TelegramAlertJob.perform_later(
        warn_message(device, tenant),
        alert_context(device, tenant, action: "warn")
      )
      true
    end

    def should_warn?(device)
      warned_at = device.metadata&.dig(METADATA_WARNED_AT)
      return true if warned_at.blank?

      parsed = Time.zone.parse(warned_at.to_s)
      return true unless parsed

      parsed < (@now - 7.days)
    end

    def expired_message(device, tenant)
      "Device token **истёк** — устройство отключено.\n" \
        "Точка: #{tenant.name}\n" \
        "Устройство: #{device.name} (#{device.device_type})\n" \
        "Действие: manager → devices → «Новый токен» и обновить на железе."
    end

    def warn_message(device, tenant)
      days = device.token_expires_in_days
      "Device token **скоро истекает** (#{days} дн.).\n" \
        "Точка: #{tenant.name}\n" \
        "Устройство: #{device.name} (#{device.device_type})\n" \
        "Действие: manager → devices → «Новый токен» до истечения."
    end

    def alert_context(device, tenant, action:)
      {
        tenant: tenant.name,
        tenant_id: tenant.id,
        device_id: device.id,
        device_name: device.name,
        device_type: device.device_type,
        token_expires_at: device.token_expires_at&.iso8601,
        action: action
      }
    end
  end
end
