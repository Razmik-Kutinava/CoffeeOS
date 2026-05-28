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

- [x] Адаптер провайдера Т-Банк — `app/services/payments/tbank_adapter.rb` *(2026-05-28)*
- [x] `OrderCreator` вызывает адаптер при `pending_payment`, сохраняет `provider_payment_id`, возвращает `payment_url` *(2026-05-28)*
- [x] `Shop::Api::OrdersController` — возвращает `payment_url` в JSON ответе *(2026-05-28)*
- [x] Callback: `Callbacks::TbankController` + `POST /callbacks/tbank` — верификация Token, маппинг статусов *(2026-05-28)*
- [x] `PaymentStatusUpdater` — добавлено `Inventory::OrderRecipeDeduction` при `succeeded` *(2026-05-28)*
- [x] Тесты: `test/services/payments/tbank_adapter_test.rb` (11 тестов), `test/controllers/callbacks/tbank_controller_test.rb` (8 тестов) *(2026-05-28)*
- [x] Витрина: выбор card/sbp/cash, редирект на `payment_url`, без double-submit *(2026-05-28)*
- [ ] Staging: `SHOP_SIMULATE_PAYMENT=0` + тестовый ключ задеплоен (`fly secrets set`)
- [ ] Manager: pending payments при закрытии смены — проверить на live payment
- [ ] Киоск: reuse shop payment flow — [`KIOSK.md`](KIOSK.md)

---

## ENV (черновик)

| Переменная | Назначение |
|------------|------------|
| `SHOP_SIMULATE_PAYMENT` | `0` на боевом приёмочном стенде |
| `CALLBACK_*` | Секреты callback (см. существующие в проекте) |
| `TBANK_TERMINAL_KEY` | TerminalKey терминала (тест: `1719235292292DEMO`) |
| `TBANK_PASSWORD` | Password терминала |
| `TBANK_RETURN_URL` | Базовый URL приложения для SuccessURL/FailURL (напр. `https://coffeeos.fly.dev`) |

Не коммитить секреты.

---

## Не в scope этого дока

- Фискализация / ОФД — отдельные callbacks, частично в schema
- Оплата **наличными на barista POS** — уже в В1 (не шлюз витрины)

---

## QA

`docs/agents/AGENTS/qa_scenarios.md` — секция **[ВЕХА 2] Реальная оплата**.
