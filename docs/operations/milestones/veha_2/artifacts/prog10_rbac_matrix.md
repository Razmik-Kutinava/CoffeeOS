# Прогон 10b — RBAC матрица (prod, 2026-06-01)

**Стенд:** `https://coffeeos.fly.dev` · пароль `demo123456`

≥3 сценария на роль (логин + 2 действия в панели). Инструмент: MCP Chrome DevTools + curl-скрипт UK.

| Роль | Email | S1 | S2 | S3 | Итог |
|------|-------|----|----|-----|------|
| uk_global_admin | uk@ | `/admin` дашборд | Beta p2/p3 create (TEN) | open_as_manager → devices | **PASS** |
| franchise_manager | franchise@ | `/manager` | switcher точек A/B | список заказов | **PASS** |
| general_manager | gm-a@ | `/manager` дашборд | `/manager/devices` киоски | заказы #202606-* | **PASS** |
| shift_manager | shift-a@ | `/manager` | sidebar без Персонал/Устройств | смены/заказы | **PASS** (прогон 5 + регрессия) |
| barista A | barista-a@ | `/barista` | очередь ACCEPTED #202606-* | заказы Prog10/curl в табло | **PASS** |
| barista B | barista-b@ | `/barista` | табло B | — | **PASS** |
| prep_kitchen_manager | pk-manager@ | `/prep_kitchen` | дашборд цеха | движения/склад | **PASS** (прогон 5) |
| prep_kitchen_worker | pk-worker@ | `/prep_kitchen` | просмотр | — | **PASS** (прогон 5) |
| prog10 barista | prog10-bar-a1@prog10.local | `/barista` | точка Alpha p1 | заказы на табло | **PASS** (10c) |
| prog10 GM | prog10-gm-a1@prog10.local | `/manager` | (карточка УК ✓) | — | **PASS** (карточка) |
| AUTH-10 logout | любой | `/login` после «Выйти» | — | — | **PASS** (10c) |
| негатив | uk@ + bad pwd | остаётся `/login` | — | — | **PASS** |

**Barista ↔ заказ:** curl/kiosk/MCP checkout → заказы на `/barista` (Demo A). Цех — отдельный tenant `demo-prep-kitchen`; связь shop→barista на точке продаж **PASS**.
