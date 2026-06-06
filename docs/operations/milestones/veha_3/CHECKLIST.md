# Веха 3 — Operations & Fulfillment («Цех и склад»)

**Старт:** после закрытия В2 (или параллельно по приоритету продукта).  
**Продукт:** `docs/product/development_roadmap.md` § «ВЕХА 3».

**Цель вехи:** сквозной fulfillment (точка продаж ↔ цех заготовок), полный журнал склада, refund, offline — без блокировки текущего prod-потока «витрина → оплата → барista → выдача».

---

## A. Цех заготовок ↔ точка продаж

> **Сейчас (В2):** заказ с витрины/барista живёт в tenant **точки** (`Current.tenant_id` точки A). Панель `/prep_kitchen` — **отдельный tenant** цеха; автоматической передачи заказа из точки в цех **нет**.

- [ ] **Модель связи точка ↔ цех** — org-level или tenant-link: какая точка питается каким prep_kitchen tenant
- [ ] **Создание задания в цехе** при `accepted` заказа на точке (асинхронно, idempotent)
- [ ] **Статусы цеха** → отражение на табло точки (готовность полуфабриката / «можно выдавать»)
- [ ] **RLS и безопасность** — цех видит только свои задания; точка не видит чужие org
- [ ] **Демо-сценарий** — заказ с витрины точки A → задание в prep_kitchen → барista видит готовность
- [ ] **Документация** — `PREP_KITCHEN.md`, логины, QA-прогон

---

## B. Склад (Event Sourcing)

- [ ] Каждое списание/приход — строка `StockMovement` (техдолг В1–В2)
- [ ] Nightly reconciliation
- [ ] Анти-фрод смены (расширение audit)

---

## C. Платежи

- [ ] Refund через Т-Банк API
- [ ] Reconciliation платежей vs банк

---

## D. Offline / киоск Flutter

- [ ] Offline POS sync (см. `veha_2/OFFLINE_SYNC.md`)
- [ ] Flutter-киоск (см. `veha_2/KIOSK.md`, `FLUTTER.md`)

---

## E. Безопасность / hardening (хвост из В2)

Перенесено из [`veha_2/checklists/CHECKLIST.md`](../veha_2/checklists/CHECKLIST.md) блок 4 *(решение 2026-06-02)*.

| ID | Задача | Источник | Когда |
|----|--------|----------|--------|
| **V3-SEC-07** | Убрать `shop-api-key` из `<meta>` в `app/views/shop/shop.html.erb`; ключ только header/session/сервер | CODE_REVIEW SEC-07, V2-SEC-07 | До боевого домена / prod hardening (не блокер demo Fly) |

- [ ] **V3-SEC-07** — PR: убрать meta key, обновить shop Svelte/Flutter curl (`FLUTTER_API.md`), smoke витрины

---

## Критерий «Веха 3 стартована»

1. Задача **A** зафиксирована в roadmap и не блокирует В2 prod.
2. Solid Queue + Solid Cable на инфре — без `perform_now` / без F5 на табло *(закрывается в хвосте В2)*.

**Дата старта:** ____________  
**Хвосты из В2:** Solid Queue/Cable, §I приёмка, киоск Flutter
