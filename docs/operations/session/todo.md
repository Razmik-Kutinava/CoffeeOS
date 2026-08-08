# todo — #47 PWA status sync + repeats stale (SPEC 2026-08-08)

**ТЗ:** [`customer_tasks/Статусы с табло не подтягиваются в PWA и повторы после заказа.md`](../milestones/veha_2/requirements/customer_tasks/Статусы%20с%20табло%20не%20подтягиваются%20в%20PWA%20и%20повторы%20после%20заказа.md)  
**Артефакты:** [`pwa_status_sync_and_repeats_stale/`](../milestones/veha_2/artifacts/pwa_status_sync_and_repeats_stale/) · скрин `01_aram_empty_sheet_plus0.png`  
**Родители:** #35 Cable/sheet · #42 TTL active · #43 hide repeat (TTL) — здесь **live sync**, не June stale  
**Стек:** `OrderStatusSheet.svelte` · `orderStatusSheet.js` · `frequentRepeatStore.js` · паттерн `catalog.js` polling

---

## PHASE 0: DOCS

- [x] customer_tasks 1:1 + artifacts + CBR #47
- [x] ISSUES 🔴 open

---

## Файлы (ожидаемо)

1. `app/frontend/components/OrderStatusSheet.svelte` — polling `/orders/active` + `visibilitychange`; после sync → `refreshFrequentProducts`
2. `app/frontend/lib/orderStatusSheet.js` — хелперы poll/tick (если выносим; иначе только Sheet)
3. `app/frontend/lib/frequentRepeatStore.js` — убедиться, что refresh после terminal/poll сбрасывает stale cache
4. `app/frontend/lib/stores/catalog.js` — **референс** паттерна poll (не менять без нужды)
5. `test/javascript/...` или существующий JS-тест зоны status/frequent — RED на poll/visibility + refresh frequent

*(добор при BUILD, max +1–2: `shopOrderCable.js` только если трогаем reconnect)*

---

## Канон / Gaps

| ID | Gap | Prio | Статус |
|----|-----|------|--------|
| **G1** | Polling `GET /orders/active` пока sheet mounted (интервал ~каталог 8s или 5–10s) | P0 | `[ ]` |
| **G2** | `visibilitychange` → visible → `refreshActive` + `refreshFrequentProducts` | P0 | `[ ]` |
| **G3** | После любого sync (poll / cable terminal / reconnect) — `refreshFrequentProducts` | P0 | `[ ]` |
| **G4** | Cable остаётся fast-path; poll — страховка (не заменять WS) | MUST | `[ ]` |
| R1 | Не ломать hide «повторить» при реальном active (`accepted/preparing/ready` ≤24h) | MUST | `[ ]` |
| R2 | `ready` по-прежнему hide из status sheet (#35) — UX пустой низ чинится через G3 (повторы после issued; при ready без позиций — не вечный `+0₽` без смысла) | SHOULD | `[ ]` |

---

## План SBR

### RED
1. `[x]` Тест: tick/poll вызывает refresh active (+ frequent hook)
2. `[x]` Тест: visibility visible → refresh
3. `[x]` Коммит `test: … [RED]` — `order_status_active_poll_test.mjs` 6/0 fail (ожидаемо)

### GREEN
1. `OrderStatusSheet`: `setInterval` + visibility (как `startCatalogPolling`)
2. После `refreshActive` / terminal — `refreshFrequentProducts`
3. Регрессия shop/status/frequent zone
4. Коммит `feat: … [GREEN]`

### REVIEW
Ops + MCP Fly: смена статуса на табло без F5 в PWA; после issued — «повторить» без reload

---

## Exit Criteria

1. `[ ]` Бариста меняет статус → PWA обновляет без перезагрузки (≤ poll interval)
2. `[ ]` После issued — повторы/история частот без F5
3. `[ ]` Тесты зелёные · GREEN · ops · MCP
4. `[ ]` Апрув заказчика «ок»
