# IB — техдолг и открытые дыры (2026-08-31)

**Статус:** живой регистр · **не** дублирует закрытые G-01…G-12 Phase 4  
**Связано:** [phase_4_rbac_dod/README.md](phase_4_rbac_dod/README.md) · [phase_5b_hardening/README.md](phase_5b_hardening/README.md) · [DEVICE_TOKENS.md](phase_3_tenant_rls/DEVICE_TOKENS.md)

> Контур RBAC/RLS **закрыт с оговорками** (Phase 4 DoD). Продуктовый docs-drift (IB-P-03/04) — **FIXED** 2026-08-31.

---

## 🔴 Критично (дыры / fix до prod sign-off)

| ID | Область | Дыра | Severity | Статус |
|----|---------|------|----------|--------|
| IB-D-01 | **G-12 prep link** | POST без проверки org | **medium** | **FIXED** 2026-08-31 — `SalesPointRegistry#validate_same_organization!`, model validation, controller candidate gate, tests |
| IB-D-02 | **V2-SEC-08** | `bundler-audit` CVE | **high** (infra) | **FIXED** 2026-08-31 — rails 8.1.3.1, puma 8.0.2, nokogiri 1.19.4; Gemfile floors; `bin/bundler-audit check` clean |
| IB-D-03 | **Shop API key** (V2-SEC-07) | ключ в meta витрины | **medium** | **FIXED** 2026-08-31 — meta удалён; browser CSRF+Referer; MCP scripts → `SHOP_API_KEY` env |

---

## 🟡 Средне (defense in depth, не cross-tenant leak)

| ID | Область | Gap | Severity | Что сделать |
|----|---------|-----|----------|-------------|
| IB-D-04 | **Prep kitchen Pundit** | `queue`, `dashboard`, `recipes`, `reports`, `incidents`, `stop_list` — только `base#require_prep_kitchen_role`, **без** `authorize` / `verify_authorized`. Различие manager/worker — ручное (`stop_list#no_rights`). | low–medium | **FIXED** 2026-08-31 — `PrepKitchen::*Policy` + authorize; worker read dashboard/queue/stop_list; manager-only recipes/reports/incidents |
| IB-D-05 | **Manager dashboard** | `DashboardController#show` без Pundit — опирается на base role gate. | low | **FIXED** 2026-08-31 — `Manager::DashboardPolicy#show?` + authorize |
| IB-D-06 | **blog_editor** | `has_role?("blog_editor")` **глобально**, не `has_role_in_context?`. Отдельный CMS-контур. | low | **FIXED** 2026-08-31 — global role in `has_role_in_context?`; blog uses context API; UserRole без tenant_id |
| IB-D-07 | **Device TTL без cron** | Истёкший token → 401, но `is_active` остаётся true | low (ops) | **FIXED** 2026-08-31 — `RotateExpiringTokensJob` деактивирует + warn alerts |
| IB-D-08 | **User#has_role_in_context?` else`** | Неизвестные role codes падают в `roles.exists?(code: code)` без tenant_id. | low | **FIXED** 2026-08-31 — else → deny; unknown codes не дают global grant |

---

## 🟢 Shop — REVIEW закрыты (2026-08-31)

| ID | Endpoint / тема | Было | Статус |
|----|-----------------|------|--------|
| G-04 | `GET /shop/api/phone_otp/status` auto-bind | auto `set_customer_id!` по phone | **FIXED** — только session customer с совпадающим phone |
| G-05 | `DELETE /shop/api/session` + refresh_token | деактивация чужого refresh | **FIXED** — deactivate только если `ms.customer_id` == session customer |
| — | `GET /shop/api/categories` public | без dedicated rate limit | **FIXED** — `shop/categories` 60/min per IP |
| — | `GET /shop/api/user/cards` по email param | GuestCustomerResolver(email) | **FIXED** — session `customer_id` only; F5 через `email_otp/status` |

---

## 📦 Продуктовый долг (docs / scope — не дыра RLS)

| ID | Задача | Статус |
|----|--------|--------|
| IB-P-01 | **G-12 multi-point** | **FIXED** 2026-08-31 — links + UI + org guard + wiring + platform UI |
| IB-P-02 | **Device token cron** | **FIXED** 2026-08-31 |
| IB-P-03 | **Docs drift favorites** | **FIXED** 2026-08-31 — ROLES §7, SHOP matrix, ACTORS sync G-06 |
| IB-P-04 | **Phase 4 G-12 gap register** | **FIXED** 2026-08-31 — G-12 row: data + MVP UI + full wiring vs IB-P-01 |
| IB-P-05 | **Fly / IB re-verify** | **FIXED** 2026-08-31 — v472 MCP 7/7 |

---

## ✅ Закрыто недавно (не долг)

- G-01…G-03 device lookup RLS · G-06 favorites DB · G-11 user_roles · **IB-D-01…08** · **G-12 wiring** · **IB-P-02 cron** · ABAC · legacy shop CI

---

## Приоритет следующего шага

1. Deploy по апруву (v472+ на Fly) · мониторинг Sentry/УК по запросу
2. Blog CMS hardening (G-10 backlog) — вне coffee ops hot-path
