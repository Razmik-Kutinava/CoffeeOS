# frozen_string_literal: true

module Shop
  # B1.14-3b: нормализация города и расстояние между точками (haversine).
  module TenantGeo
    EARTH_RADIUS_KM = 6_371.0

    module_function

    def normalize_city(city)
      city.to_s.strip.downcase.tr("ё", "е")
    end

    def coordinates?(tenant)
      tenant.latitude.present? && tenant.longitude.present?
    end

    # Километры; nil если нет координат у одной из точек.
    def distance_km(from_tenant, to_tenant)
      return nil unless coordinates?(from_tenant) && coordinates?(to_tenant)

      haversine_km(
        from_tenant.latitude.to_f, from_tenant.longitude.to_f,
        to_tenant.latitude.to_f, to_tenant.longitude.to_f
      )
    end

    def haversine_km(lat1, lng1, lat2, lng2)
      d_lat = radians(lat2 - lat1)
      d_lng = radians(lng2 - lng1)
      a = Math.sin(d_lat / 2)**2 +
          Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(d_lng / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      EARTH_RADIUS_KM * c
    end

    def radians(degrees)
      degrees * Math::PI / 180.0
    end
    private_class_method :radians
  end
end
