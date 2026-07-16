# frozen_string_literal: true

# Read-only prod stats for UserCards Фаза 0 (runs on Fly via rails runner).
require "json"

data = {}
data[:env] = {
  shop_simulate_payment: ENV.fetch("SHOP_SIMULATE_PAYMENT", nil),
  tbank_terminal_set: ENV["TBANK_TERMINAL_KEY"].to_s.present?,
  tbank_rsa_set: ENV["TBANK_RSA_PUBLIC_KEY"].to_s.present?
}
data[:counts] = {
  mobile_payment_methods_card: MobilePaymentMethod.where(payment_type: "card").count,
  mobile_customers: MobileCustomer.count,
  payments_tbank_30d: Payment.where(provider: "tbank").where("created_at > ?", 30.days.ago).count,
  payments_tbank_succeeded_30d: Payment.where(provider: "tbank", status: :succeeded).where("created_at > ?", 30.days.ago).count,
  payments_shop_30d: Payment.where(provider: "shop").where("created_at > ?", 30.days.ago).count
}
data[:recent_tbank_payments] = Payment.where(provider: "tbank").order(created_at: :desc).limit(10).map do |p|
  o = p.order
  {
    payment_id: p.id,
    status: p.status,
    provider_payment_id: p.provider_payment_id,
    save_card: (p.provider_data.is_a?(Hash) ? p.provider_data["save_card"] : nil),
    created_at: p.created_at&.iso8601,
    customer_email: o&.customer&.email,
    customer_id: o&.customer_id
  }
end
data[:recent_cards] = MobilePaymentMethod.includes(:customer).where(payment_type: "card").order(last_used_at: :desc, created_at: :desc).limit(10).map do |c|
  {
    id: c.id,
    customer_id: c.customer_id,
    email: c.customer&.email,
    card_masked: c.card_masked,
    card_brand: c.card_brand,
    card_token_present: c.card_token.present?,
    last_used_at: c.last_used_at&.iso8601,
    created_at: c.created_at&.iso8601
  }
end
data[:gmail_customers_sample] = MobileCustomer.where("email ILIKE ?", "%gmail.com%").order(updated_at: :desc).limit(5).map do |c|
  { email: c.email, name: c.first_name, updated_at: c.updated_at&.iso8601 }
end
puts JSON.generate(data)
