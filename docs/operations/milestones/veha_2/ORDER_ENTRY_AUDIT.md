# Аудит входов заказа — Веха 2

**Наследие В1:** [`../veha_1/ORDER_ENTRY_AUDIT.md`](../veha_1/ORDER_ENTRY_AUDIT.md) (гибрид смены зафиксирован).

**Зачем:** любой новый канал (киоск, offline replay) — сначала строка здесь, потом код и тест.

---

## Решение В1 (не менять молча)

| Канал | `CashShift` | `cash_shift_id` |
|-------|-------------|-----------------|
| Shop `/shop/api/orders` | не требуется | NULL |
| Barista POS | обязательна open | обязателен |
| Киоск (план В2) | **как shop** (пока) | NULL |
| Offline replay (план) | TBD § F главного чеклиста | TBD |

**В2 опционально (продукт):** единый запрет без смены на **всех** каналах — `qa_scenarios` 3.V2-1.

---

## Реестр входов

| # | Вход | Файл / статус | Смена | Тест |
|---|------|---------------|-------|------|
| 1 | Shop checkout | `Shop::OrderCreator` | V1 гибрид | `shop/` integration |
| 2 | Shop API | `shop/api/orders_controller` | делегирует | да |
| 3 | Barista create | `Barista::OrderCreationService` | open shift | block_g |
| 4 | Barista controller guards | `barista/orders_controller` | open shift | block_g |
| 5 | Barista cancel | `OrderCancellationService` | open + reason | block_g |
| 6 | Payment callback | `Callbacks::PaymentStatusUpdater` | не создаёт Order | callbacks tests |
| 7 | **Kiosk** | `Device(device_type:kiosk)` + `device_token`; регистрация в manager/devices *(2026-05-28)*; API `/kiosk/api/...` ждёт Flutter; OrderCreator + Т-Банк готовы | NULL (как shop) | TBD (Flutter) |
| 8 | **Offline sync POST** | _TBD В2_ | TBD | O-1…O-3 qa |

**Gate:** новый # → PR → строка в [`CHECKLIST.md`](CHECKLIST.md) § D/F → `qa_scenarios.md`.

---

## Идемпотентность (В2)

Клиентские POST заказа: ключ `tenant_id:device_id:client_uuid` — см. `docs/product/ARCHITECTURE.md`.

| Канал | client_uuid | Статус |
|-------|-------------|--------|
| Shop | _план В2_ | |
| Kiosk | _план В2_ | |
| Callback | `X-Idempotency-Key` | **В1 есть** |

---

## История изменений

- **2026-05-28** — Киоск: регистрация устройства в manager/devices реализована; API ждёт Flutter.
- **2026-05-25** — Создан реестр В2; киоск/offline — заглушки до реализации.
