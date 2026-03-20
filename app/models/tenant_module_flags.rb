# frozen_string_literal: true

# Модули точки (feature_flags.module) — вкл/выкл из админки УК.
class TenantModuleFlags
  LABELS = {
    "kiosk" => "Киоск",
    "prep_kitchen" => "Заготовочный цех",
    "barista" => "Касса / бариста",
    "menu" => "Меню точки",
    "qr_offers" => "QR / офферы",
    "tv_board" => "TV-борд"
  }.freeze

  def self.modules
    LABELS.keys
  end

  # raw: хэш "module" => "0"|"1"|true|false; отсутствующие ключи для новых записей → enabled true.
  def self.sync!(tenant, raw)
    bool = ActiveModel::Type::Boolean.new
    h = (raw || {}).stringify_keys
    modules.each do |mod|
      ff = FeatureFlag.find_or_initialize_by(tenant_id: tenant.id, module: mod)
      ff.enabled =
        if h.key?(mod)
          bool.cast(h[mod])
        elsif ff.new_record?
          true
        else
          ff.enabled
        end
      ff.save!
    end
  end
end
