class Device < ApplicationRecord
  belongs_to :tenant
  belongs_to :registered_by, class_name: "User", optional: true
  has_many :device_sessions, dependent: :destroy
  has_many :order_status_logs, dependent: :nullify
  has_many :kiosk_settings, dependent: :destroy
  has_many :kiosk_carts, dependent: :destroy
  has_many :kiosk_sessions, dependent: :destroy

  validates :device_type, presence: true, inclusion: { in: %w[barista_tablet tv_board kiosk smart_locker] }
  validates :name, presence: true
  validates :device_token, uniqueness: true, allow_nil: true

  scope :active, -> { where(is_active: true) }
  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :online, -> { where("last_seen_at > ?", 2.minutes.ago) }

  def online?
    last_seen_at.present? && last_seen_at > 2.minutes.ago
  end

  def token_valid?
    return false if device_token.blank?
    return true if token_expires_at.blank?

    token_expires_at > Time.current
  end

  def token_expired?
    token_expires_at.present? && token_expires_at <= Time.current
  end

  def token_expires_in_days
    return nil if token_expires_at.blank?

    ((token_expires_at - Time.current) / 1.day).ceil
  end

  def token_expiring_soon?
    return false if token_expires_at.blank? || token_expired?

    token_expires_in_days <= 14
  end

  def token_expiry_label
    return expiry_label_without_date if token_expires_at.blank?
    return "истёк #{token_expires_at.strftime('%d.%m.%Y %H:%M')}" if token_expired?

    days = token_expires_in_days
    suffix = days == 1 ? "1 день" : "#{days} дн."
    "до #{token_expires_at.strftime('%d.%m.%Y')} (#{suffix})"
  end

  def token_expiry_status
    return :unlimited if token_expires_at.blank?
    return :expired if token_expired?
    return :soon if token_expiring_soon?

    :active
  end

  # Per-TV режим: "ads" | "orders" (в metadata). Лимит карточек — tenant-wide из TvBoardSetting.
  TV_MODE_ADS = "ads".freeze
  TV_MODE_ORDERS = "orders".freeze

  def tv_ads_mode?
    (metadata || {})["tv_mode"].to_s == TV_MODE_ADS
  end

  def tv_effective_show_order_count(tv_setting)
    limit = tv_setting.show_order_count.to_i
    return 0 if tv_ads_mode?

    limit
  end

  private

  def expiry_label_without_date
    ttl = Devices::TokenCredentials.ttl_days
    if ttl
      "без срока (legacy; новые — #{ttl} дн.)"
    else
      "без срока"
    end
  end
end
