# MCP — #78 slice-5 Shop API (Fly v490)

**Дата:** 2026-09-08 · Point A · **PARTIAL**

| Step | Result | Notes |
|------|--------|-------|
| deploy/up | PASS | v490 · `/up` 200 |
| GET current без sub | PASS | **404** `Подписка не найдена` |
| GET без session | PASS | **401** |
| POST create | **SKIP** | нет RebillId cards у guest; `SubscriptionPlan` на Fly **[]** → 422 `plan not found` |
| GET current after | SKIP | нет purchase |
| order closed | SKIP | нет purchase |
| auto_renew | N/A | GET/PATCH без sub → 404 (ожидаемо) |
| cancel | PASS | **501** `not_implemented` slice 3 |
| confirm_payment | PASS | **501** slice 4 |
| duplicate 422 | SKIP | нет active sub |
| inactive PM | SKIP | нет cards |
| #77 config/profile | PASS | `subscription_offer` + `eligible_for_subscription_offer` |
| UserCards smoke | PASS | 200 empty cards array |

## Пачка
- Sentry 24h unresolved: 0
- Fly logs: без Exception на subscriptions routes
- Neon: local MCP ≠ Fly DB

## Чинить / backlog
- Seed `SubscriptionPlan` на Fly + test guest с RebillId для live Charge
- Не баг slice-5 API контракта (401/404/501 OK)
