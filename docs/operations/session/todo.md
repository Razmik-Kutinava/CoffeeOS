# todo — CODE:BLACK T-Kassa SBP · PWA lifecycle (ревизия)

> **ТЗ:** [`customer_tasks/Интеграция Т-Кассы СБП и токенизации в PWA CODE BLACK.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20Т-Кассы%20СБП%20и%20токенизации%20в%20PWA%20CODE%20BLACK.md)  
> **Артефакты:** [`artifacts/codeblack_t_kassa_sbp_tokenization/`](../milestones/veha_2/artifacts/codeblack_t_kassa_sbp_tokenization/)  
> **Предшественник v2:** [`todo` волны A–D закрыты](todo.md) · Fly v394 · [`sbp_deep_link_card_tokenization/`](../milestones/veha_2/artifacts/sbp_deep_link_card_tokenization/)

## Текущая фаза

**PHASE 3: REVIEW** — Fly **v395** · MCP PASS · ждём апрув заказчика  
*(код `[x]`; push+deploy `[x]`; MCP `[x]`)*

---

## Маппинг путей ТЗ → CoffeeOS

| ТЗ | Канон CoffeeOS | Решение SPEC |
|----|----------------|--------------|
| `POST /api/v1/payments/sbp/init` | `POST /shop/api/payments/sbp/init` | **уже есть** (v2) |
| `POST .../card/init` | `POST /shop/api/payments/new_card` | **reuse** |
| `POST .../charge-recurrent` | `POST /shop/api/payments/one_click` | **reuse** (RebillId серверно, не с клиента plaintext) |
| `POST .../webhook` | `POST /callbacks/tbank` | **reuse**; invalid Token → **401** (канон) |
| `GET .../payments/status/:orderId` | новый тонкий `GET /shop/api/payments/status/:order_id` | **добавить** → `{ status: PENDING\|CONFIRMED\|REJECTED\|CANCELED }` |
| `codeblack_pending_order` | `localStorage` ключ тот же | **новый** `lib/codeblackPendingOrder.js` |
| Jest/React paths | `test/javascript/*.mjs` + Rails integration | стек **Rails 8 + Svelte** |

---

## As-is → Gap (только дельта)

| # | Есть (v2) | Gap этой ревизии |
|---|-----------|------------------|
| B1–B3 | Init+Receipt, GetQr, sbp/init, webhook, Recurrent, Charge, SBP CTA, poll 60s/2s | Characterization; тонкий status GET |
| G10 | SuccessURL → `#/payment-result` + poll finalize | Нет `codeblack_pending_order` до redirect |
| G11 | `pageshow` + guest session recover | Нет `visibilitychange` по pending LS; нет TTL 15 мин |
| G12 | PaymentResult loading / incomplete | Нет экрана WAITING_FOR_BANK + «Я оплатил» |

### Ограничения (соблюдать)

- Нет iframe/виджета Т-Банка.
- В LS только `{ orderId, timestamp }` (+ маска карты уже в UI, не RebillId).
- Race: повторный `visibilitychange` не запускает параллельные poll (mutex/in-flight flag).
- Expired pending (>15 мин) — игнорировать и чистить.

### File-size

| Файл | План |
|------|------|
| `codeblackPendingOrder.js` | **create** ≤80 |
| `shopSbpPay.js` | extend: `checkOrderStatus`, waiting copy; не раздувать |
| `PaymentResult.svelte` | waiting UI + «Я оплатил» |
| `App.svelte` | cold start + visibilitychange hook |
| `Checkout.svelte` | save pending перед redirect |
| `payments_controller#status` | тонкий show |

**DDL:** не требуется.

---

## Волны

| Волна | Шаги ТЗ | Суть |
|-------|---------|------|
| **E0** | 1–3, 5.1 | Characterization / reuse (без нового кода кроме status GET) |
| **E1** | 4.1–4.3, 5.2 | Pending LS + visibility + cold start + WAITING_FOR_BANK |

Первый RED: `codeblackPendingOrder` + status mapping + waiting UI tests.

---

## Чеклист TDD

### Backend (reuse / thin)
- [x] 1.1 sbp/init — **reuse v2**
- [x] 2.1 card/init — **reuse** `new_card`
- [x] 2.2 charge-recurrent — **reuse** `one_click`
- [x] 3.1 webhook — **reuse** `/callbacks/tbank`
- [x] 3.2 `GET /shop/api/payments/status/:order_id` → PENDING/CONFIRMED/REJECTED/CANCELED

### Frontend lifecycle (gap)
- [x] 4.1 save `codeblack_pending_order` перед redirect + WAITING_FOR_BANK
- [x] 4.2 `visibilitychange` → `checkOrderStatus`; clear на финале
- [x] 4.3 cold start: TTL &lt; 15 мин → status + экран
- [x] 5.1 checkout SBP/card CTA — **reuse v2**
- [x] 5.2 экран ожидания + «Я оплатил»

---

## Тесты / регрессия

| Зона | Команда |
|------|---------|
| JS pending + status | `node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs` |
| Status API | `bin/rails test test/integration/shop/api/payment_status_test.rb` |
| Оплата §2.3 | по `coffeeos-dev-gates.mdc` (payment cart + stage5 + order_creator) |

---

## Риски

| Риск | Митигация |
|------|-----------|
| Двойной poll (payment-result + visibility) | in-flight guard; clear pending после terminal |
| Клиент шлёт RebillId в charge | one_click принимает `card_id`, не raw RebillId — **не** менять контракт под plaintext из ТЗ |
| Status enum ≠ order.status | явный mapper payment/order → 4 статуса ТЗ |
