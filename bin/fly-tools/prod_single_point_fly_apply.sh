#!/usr/bin/env bash
# Apply single-point cleanup on Fly prod via rails runner (inline — works before deploy).
set -euo pipefail

DRY_RUN="${DRY_RUN:-1}"
APP="${FLY_APP:-coffeeos}"

read -r -d '' RUBY <<'RUBY' || true
keep = "2fdee1ac-4674-41ee-b89e-87b45643f789"
dry = ENV.fetch("DRY_RUN", "1") != "0"
point_a = Tenant.find(keep)
kitchen_ids = Tenant.where(
  organization_id: point_a.organization_id,
  type: "production_kitchen",
  status: "active"
).pluck(:id).map(&:to_s)
keep_ids = ([keep] + kitchen_ids).uniq
before = {
  orders: Order.where(tenant_id: keep).count,
  payments: Payment.where(tenant_id: keep).count,
  active_sales: Tenant.where(status: "active", type: "sales_point").order(:slug).pluck(:slug, :id)
}
deactivated = []
Tenant.where(type: "sales_point").where.not(id: keep_ids).find_each do |t|
  next if t.status.to_s == "inactive"
  t.update!(status: "inactive") unless dry
  deactivated << { slug: t.slug, id: t.id, name: t.name }
end
unless dry
  updates = {}
  updates[:address] = "ул. Ленина, 10" if point_a.address.blank?
  updates[:city] = "Москва" if point_a.city.blank?
  updates[:status] = "active"
  point_a.update!(updates) if updates.present?
end
after_active = Tenant.where(status: "active", type: "sales_point").order(:slug).pluck(:slug, :id)
payload = {
  dry_run: dry,
  keep_ids: keep_ids,
  before: before,
  deactivated: deactivated,
  after_active_sales: after_active,
  orders_after: Order.where(tenant_id: keep).count
}
puts JSON.pretty_generate(payload)
fail "expected single active sales point" if !dry && after_active.size != 1
RUBY

fly ssh console -a "$APP" -C "DRY_RUN=$DRY_RUN bin/rails runner \"$RUBY\""
