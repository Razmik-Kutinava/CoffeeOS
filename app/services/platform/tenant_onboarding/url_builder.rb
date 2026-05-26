# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Канонический URL витрины точки (поддомен = tenants.slug).
    class UrlBuilder
      RESERVED_SUBDOMAINS = %w[www app admin api mail ftp].freeze

      def self.shop_url_for(tenant)
        dom = shop_base_domain
        return "/shop?tenant_id=#{tenant.id}" if dom.blank?

        slug = tenant.slug.to_s
        return "/shop?tenant_id=#{tenant.id}" if slug.blank? || RESERVED_SUBDOMAINS.include?(slug)

        scheme = Rails.env.production? ? "https" : "http"
        port =
          if Rails.env.development?
            p = ENV.fetch("PORT", 3001).to_i
            p == 80 || p == 443 ? "" : ":#{p}"
          else
            ""
          end

        "#{scheme}://#{slug}.#{dom}#{port}/shop"
      end

      # Поддомены только при явном SHOP_BASE_DOMAIN (свой DNS + fly certs).
      # На coffeeos.fly.dev нет DNS/TLS для {slug}.coffeeos.fly.dev — без env ссылки идут с ?tenant_id=.
      def self.shop_base_domain
        ENV["SHOP_BASE_DOMAIN"].presence
      end

      # Соответствие поддомена хоста записи Tenant.slug (для витрины /shop).
      def self.tenant_id_for_host(host)
        base = shop_base_domain
        return nil if base.blank? || host.blank?

        suffix = ".#{base}"
        return nil unless host.to_s.end_with?(suffix)

        prefix = host.to_s.delete_suffix(suffix)
        return nil if prefix.blank?

        slug = prefix.include?(".") ? prefix.split(".").last : prefix
        return nil if slug.blank? || RESERVED_SUBDOMAINS.include?(slug)

        Tenant.find_by(slug: slug)&.id
      end
    end
  end
end
