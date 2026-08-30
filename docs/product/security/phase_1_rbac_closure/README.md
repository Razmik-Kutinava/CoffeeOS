# Phase 1 — RBAC closure (shop ownership)

**Статус:** реализовано 2026-08-30 · апрув → Phase 4

## Deliverables

| ID | Артефакт | Статус |
|----|----------|--------|
| IB-1-1 | `Shop::Api::OrderOwnership` concern | done |
| IB-1-2 | payments status / widget_init / sbp_init / sbp_charge ownership | done |
| IB-1-3 | `test/integration/shop/api/ownership_idor_test.rb` | done |
| IB-1-4 | [SHOP_API_AUTH.md](SHOP_API_AUTH.md) + matrix update | done |

## HOLE → FIXED (Phase 1)

| Endpoint | Commit area |
|----------|-------------|
| `GET payments/status/:order_id` | `PaymentsController#status` + concern |
| `POST payments/widget_init` | `PaymentsController#widget_init` |
| `POST payments/sbp/init` | `PaymentsController#sbp_init` |
| `POST payments/sbp/charge` | `PaymentsController#sbp_charge` (controller gate) |

## Next (Phase 2)

Staff Pundit / manager RBAC — отдельный промпт после апрува Phase 1.
