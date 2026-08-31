# IB — техдолг и открытые дыры (2026-08-31)

**Статус:** живой регистр · **не** дублирует закрытые G-01…G-12 Phase 4  
**Связано:** [phase_4_rbac_dod/README.md](phase_4_rbac_dod/README.md) · [phase_5b_hardening/README.md](phase_5b_hardening/README.md) · [DEVICE_TOKENS.md](phase_3_tenant_rls/DEVICE_TOKENS.md)

> Контур RBAC/RLS **закрыт с оговорками** (Phase 4 DoD). Ниже — что **ещё доделать** по ИБ и смежным задачам (G-12 UI, device TTL/cron).

---

## 🔴 Критично (дыры / fix до prod sign-off)

| ID | Область | Дыра | Severity | Статус |
|----|---------|------|----------|--------|
| IB-D-01 | **G-12 prep link** | POST без проверки org | **medium** | **FIXED** 2026-08-31 — `SalesPointRegistry#validate_same_organization!`, model validation, controller candidate gate, tests |
| IB-D-02 | **V2-SEC-08** | `bundler-audit` CVE | **high** (infra) | **FIXED** 2026-08-31 — rails 8.1.3.1, puma 8.0.2, nokogiri 1.19.4; Gemfile floors; `bin/bundler-audit check` clean |
| IB-D-03 | **Shop API key** (V2-SEC-07) | ключ в meta витрины | **medium** | open → V3 |

---

## 🟡 Средне (defense in depth, не cross-tenant leak)

| ID | Область | Gap | Severity | Что сделать |
|----|---------|-----|----------|-------------|
| IB-D-04 | **Prep kitchen Pundit** | `queue`, `dashboard`, `recipes`, `reports`, `incidents`, `stop_list` — только `base#require_prep_kitchen_role`, **без** `authorize` / `verify_authorized`. Различие manager/worker — ручное (`stop_list#no_rights`). | low–medium | Policies на read/write; worker read-only где нужно |
| IB-D-05 | **Manager dashboard** | `DashboardController#show` без Pundit — опирается на base role gate. | low | `authorize :dashboard, :show?` или явный policy |
| IB-D-06 | **blog_editor** | `has_role?("blog_editor")` **глобально**, не `has_role_in_context?`. Отдельный CMS-контур. | low | Context-aware role или UK-only assign |
| IB-D-07 | **Device TTL без cron** | Истёкший token → 401, но `is_active` остаётся true | low (ops) | **FIXED** 2026-08-31 — `RotateExpiringTokensJob` деактивирует + warn alerts |
| IB-D-08 | **User#has_role_in_context?` else`** | Неизвестные role codes падают в `roles.exists?(code: code)` без tenant_id. | low | Whitelist role codes в else → deny |

---

## 🟢 Shop — осознанные REVIEW (не HOLE, но зафиксировать)

| ID | Endpoint / тема | Риск | Статус |
|----|-----------------|------|--------|
| G-04 | `GET /shop/api/phone_otp/status` auto-bind customer по phone | Слабая привязка session↔customer при совпадении phone | **documented** by design |
| G-05 | `DELETE /shop/api/session` + refresh_token | Деактивация refresh без строгой привязки к session | **documented** REVIEW |
| — | `GET /shop/api/categories` public без API key | Каталог публичный | **by design** + rate limit backlog |
| — | `GET /shop/api/user/cards` по email param | Нужен verified email flow | REVIEW в матрице |

---

## 📦 Продуктовый долг (не дыра RLS, но G-12 / devices «не доделано»)

| ID | Задача | Сейчас | Доделать |
|----|--------|--------|----------|
| IB-P-01 | **G-12 multi-point** | Links + UI + org guard + queue/stop-list/reports/incidents + **platform UI** | — |
| IB-P-02 | **Device token cron** | `RotateExpiringTokensJob` + warn/deactivate + Telegram | **FIXED** 2026-08-31 |
| IB-P-03 | **Docs drift** | `ROLES_AND_PERMISSIONS.md` §7: favorites «session-only»; SHOP matrix favorites «session-only» | Sync: G-06 FIXED; обновить REVIEW строки |
| IB-P-04 | **Phase 4 G-12 статус** | GAP register: **FIXED** | Уточнить: **data + MVP UI**; product wiring = IB-P-01 |
| IB-P-05 | **Fly / IB re-verify** | Локально green после 2026-08-31 commits | Push → CI → deploy апрув → Prog10 + MCP Point A |

---

## ✅ Закрыто недавно (не долг)

- G-01…G-03 device lookup RLS · G-06 favorites DB · G-11 user_roles · **IB-D-01 org guard** · **IB-D-02 bundler-audit** · **G-12 queue wiring** · ABAC full enforce · legacy shop CI · device TTL banner UI

---

## Приоритет следующего шага

1. **IB-D-03** (shop-api-key V3) — клиентский ключ в meta  
2. **IB-P-05** (Fly re-verify) — push → CI → deploy апрув  
3. **IB-D-04..08** — Pundit defense in depth (backlog)
