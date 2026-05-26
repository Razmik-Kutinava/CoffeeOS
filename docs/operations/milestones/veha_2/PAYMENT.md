# Оплата — Веха 2

**Приоритет:** сразу после онбординга (витрина + QR на столах). **Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § C.

---

## Зачем

Демо В1 — имитация. В2 — **реальные деньги** на витрине (и киоске тем же pipeline), чтобы точку можно было открыть с QR без доработки POS.

---

## Как сейчас (В1)

| Env | Поведение |
|-----|-----------|
| `SHOP_SIMULATE_PAYMENT=1` (default) | Заказ сразу `accepted`, payment `succeeded`, provider `shop` |
| `SHOP_SIMULATE_PAYMENT=0` | card/sbp → `pending_payment`, payment `pending` — **ждёт callback** |

**Код:** `Shop::OrderCreator`, `Callbacks::PaymentStatusUpdater`, `Callbacks::EventsController#payment`.

**Тесты:** `test/services/shop/order_creator_test.rb`, `test/integration/shop/api/mvp_flow_test.rb`, `test/controllers/callbacks/events_controller_test.rb`.

---

## Целевой поток В2

```
Клиент (shop/QR) → create order pending_payment
  → redirect/widget шлюза (ЮKassa — целевой провайдер в qa)
  → callback POST /callbacks/payments
  → PaymentStatusUpdater → accepted → списание склада (триггер + OrderRecipeDeduction)
```

---

## Задачи реализации

- [ ] Адаптер провайдера (create payment, status, secrets через ENV)
- [ ] Витрина: UI «Оплатить» → шлюз, не simulate на prod/staging приёмки
- [ ] Callback URL + подпись (`CALLBACK_*` как в проекте)
- [ ] Staging: `SHOP_SIMULATE_PAYMENT=0` + тестовый ключ шлюза
- [ ] Manager: pending payments при закрытии смены — проверить на live payment
- [ ] Киоск: reuse shop payment flow — [`KIOSK.md`](KIOSK.md)

---

## ENV (черновик)

| Переменная | Назначение |
|------------|------------|
| `SHOP_SIMULATE_PAYMENT` | `0` на боевом приёмочном стенде |
| `CALLBACK_*` | Секреты callback (см. существующие в проекте) |
| _TBD_ | Ключи ЮKassa / return URL |

Не коммитить секреты.

---

## Не в scope этого дока

- Фискализация / ОФД — отдельные callbacks, частично в schema
- Оплата **наличными на barista POS** — уже в В1 (не шлюз витрины)

---

## QA

`docs/agents/AGENTS/qa_scenarios.md` — секция **[ВЕХА 2] Реальная оплата**.
