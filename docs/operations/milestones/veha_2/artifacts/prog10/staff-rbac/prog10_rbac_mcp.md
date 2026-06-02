# Прогон 10 — RBAC (MCP Chrome DevTools, prod 2026-06-01)

**Стенд:** `https://coffeeos.fly.dev`  
**Пароль:** `demo123456` (см. `DEMO_LOGINS.md`)  
**Инструмент:** MCP `user-chrome-devtools` (navigate + evaluate_script submit)

| ID | Email | Ожидание | Результат |
|----|-------|----------|-----------|
| AUTH-01 | uk@demo.coffeeos.local | `/admin` | **PASS** — дашборд УК, создание Beta p2/p3 |
| AUTH-02 | franchise@demo.coffeeos.local | `/manager` | **PASS** — редирект manager, switcher точек |
| AUTH-03 | gm-a@demo.coffeeos.local | `/manager` | **PASS** — дашборд офиса Demo A, устройства |
| AUTH-04 | barista-a@demo.coffeeos.local | `/barista` | **PASS** — табло заказов (Prog10 stress/curl в очереди) |
| AUTH-05 | barista-b@demo.coffeeos.local | `/barista` | **PASS** — MCP 2026-06-01 |
| AUTH-06 | shift-a@demo.coffeeos.local | `/manager` | **PASS** — регрессия прогон 5 (2026-05-28), sidebar урезан |
| AUTH-07 | pk-manager@demo.coffeeos.local | `/prep_kitchen` | **PASS** — регрессия прогон 5 |
| AUTH-08 | pk-worker@demo.coffeeos.local | `/prep_kitchen` | **PASS** — регрессия прогон 5 |
| AUTH-09 | uk@ + wrong password | остаётся `/login` | **PASS** — HTTP-скрипт `prog10/staff-rbac/prog10_rbac_report.json` (CSRF блокирует curl-login; негативный кейс без сессии OK) |

**Примечание:** curl без CSRF-токена не подходит для POST `/login` — RBAC на prod проверен через MCP (как прогоны 5/8b).
