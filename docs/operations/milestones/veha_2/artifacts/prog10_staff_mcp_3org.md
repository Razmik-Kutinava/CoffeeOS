# Прогон 10 — MCP Staff/RBAC (3 org, блок 7)

**Стенд:** `https://coffeeos.fly.dev`  
**Дата:** 2026-06-02  
**JSON:** [`prog10_staff_mcp_3org.json`](prog10_staff_mcp_3org.json)

## Scope

| Канал | Охват |
|-------|--------|
| **curl** | 9/9 точек — [`prog10_staff_isolation.json`](prog10_staff_isolation.json) |
| **MCP UI** | **3 org × 1 точка:** Demo `demo-a`, Alpha `alpha-p1`, Beta `beta-p1` |

Сценарии: **STF-01** (open_as_manager → `/manager`), **STF-02** (`/manager/staff`, iso-barista в списке), **STF-04** (login barista → `/barista`), изоляция заказа в браузере (own JSON `200`, чужой tenant `404`).

STF-03 (создание staff в UI) — **не гоняли** (MAN по матрице сценариев).

## MCP-инструменты

1. **cursor-ide-browser** — `/login` открывается; автозаполнение пароля через fill/type **не срабатывает** (нужен `dispatchEvent('input')` — см. login-form Stimulus).
2. **user-puppeteer** — полный UI-прогон STF + XHR-проверка `/barista/orders/:id.json`.

## Итог

| Org | Точка | STF-01 | STF-02 | STF-04 | ISO JSON |
|-----|-------|--------|--------|--------|----------|
| Demo | demo-a | PASS | PASS | PASS | own 200 / foreign 404 |
| Alpha | alpha-p1 | PASS | PASS | PASS | own 200 / demo order 404 |
| Beta | beta-p1 | PASS | PASS | PASS | own 200 / demo order 404 |

**MCP 3/3 PASS.** Остальные 6 точек — только curl (9/9).

## Следующий шаг

Блок **8** (ENT-02, ENT-07, ENT-08) — **после апрува** заказчика.
