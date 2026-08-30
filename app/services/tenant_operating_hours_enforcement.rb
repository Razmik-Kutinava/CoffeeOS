# frozen_string_literal: true

# ABAC-015: shared guard for online order channels (shop/kiosk). Barista POS exempt — shift is the gate.
class TenantOperatingHoursEnforcement
  def self.accepting_online_orders?(tenant)
    return true if tenant.nil?

    TenantOperatingHours.open_now?(tenant)
  end
end
