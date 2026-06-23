# frozen_string_literal: true

module Shop
  # B1.14: формат «Город, Адрес» для витрины (шапка, API, заказ).
  module TenantAddress
    STUB = "Адрес не указан"

    module_function

    def display(city:, address:)
      parts = [city, address].map { |p| p.to_s.strip }.reject(&:blank?)
      return STUB if parts.empty?

      parts.join(", ")
    end

    def client_json(tenant)
      {
        id: tenant.id,
        name: tenant.name,
        city: tenant.city,
        address: tenant.address,
        display_address: display(city: tenant.city, address: tenant.address)
      }
    end
  end
end
