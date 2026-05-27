# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Карточка «все входы» точки для УК (ONBOARDING §4).
    class EntryPoints
      StaffItem = Data.define(:code, :label, :filled)

      ModuleItem = Data.define(:code, :label, :enabled)

      SALES_STAFF = [
        { code: "general_manager", label: "Менеджер (general_manager)" },
        { code: "barista", label: "Бариста (barista)" },
        { code: "shift_manager", label: "Сменный менеджер (shift_manager)" }
      ].freeze

      KITCHEN_STAFF = [
        { code: "prep_kitchen_manager", label: "Менеджер цеха (prep_kitchen_manager)" },
        { code: "prep_kitchen_worker", label: "Работник цеха (prep_kitchen_worker)" }
      ].freeze

      # UI киоска ещё не в routes — URL показываем как план, не как рабочую ссылку.
      KIOSK_UI_READY = false

      def self.for(tenant, host: nil)
        new(tenant, host: host).build
      end

      def initialize(tenant, host:)
        @tenant = tenant
        @host = host.presence || default_host
      end

      def build
        {
          organization_name: tenant.organization&.name,
          slug: tenant.slug,
          address: tenant.address,
          city: tenant.city,
          shop_path: shop_path,
          shop_public_url: public_url(shop_path),
          kiosk_path: kiosk_path,
          kiosk_public_url: kiosk_enabled? ? public_url(kiosk_path) : nil,
          kiosk_enabled: kiosk_enabled?,
          kiosk_ui_ready: KIOSK_UI_READY,
          login_url: public_url("/login"),
          manager_path: "/manager",
          barista_path: "/barista",
          prep_kitchen_path: "/prep_kitchen",
          modules: module_items,
          staff_items: staff_items,
          qr_hint: qr_hint
        }
      end

      private

      attr_reader :tenant, :host

      def default_host
        ENV.fetch("APP_HOST", "localhost:3001")
      end

      def shop_path
        UrlBuilder.shop_url_for(tenant)
      end

      def kiosk_path
        base = shop_path
        return "/kiosk?tenant_id=#{tenant.id}" if base.start_with?("/shop?")

        base.sub(%r{/shop\z}, "/kiosk")
      end

      def public_url(path)
        return path if path.to_s.match?(%r{\Ahttps?://})

        scheme = Rails.env.production? ? "https" : "http"
        "#{scheme}://#{host}#{path}"
      end

      def kiosk_enabled?
        FeatureFlag.find_by(tenant_id: tenant.id, module: "kiosk")&.enabled == true
      end

      def module_items
        flags = FeatureFlag.where(tenant_id: tenant.id).index_by(&:module)

        TenantModuleFlags.modules.map do |code|
          ff = flags[code]
          ModuleItem.new(
            code: code,
            label: TenantModuleFlags::LABELS[code] || code,
            enabled: ff&.enabled == true
          )
        end
      end

      def staff_items
        specs = tenant.production_kitchen? ? KITCHEN_STAFF : SALES_STAFF
        filled_codes = filled_role_codes

        specs.map do |spec|
          StaffItem.new(
            code: spec[:code],
            label: spec[:label],
            filled: filled_codes.include?(spec[:code])
          )
        end
      end

      def filled_role_codes
        UserRole
          .where(tenant_id: tenant.id)
          .joins(:role)
          .distinct
          .pluck("roles.code")
      end

      def qr_hint
        if shop_path.start_with?("/shop?")
          "QR: напечатайте ссылку витрины (режим без поддомена — tenant_id в URL)."
        else
          "QR: напечатайте ссылку витрины или используйте поддомен #{tenant.slug}.#{UrlBuilder.shop_base_domain}."
        end
      end
    end
  end
end
