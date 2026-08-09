# Аудит входов заказа — Веха 1 (гибрид смены)

**Единый источник правды** для решения A/B и сквозной проверки.  
Обновлять при **любом** новом канале создания `Order`.

**Решение В1 (зафиксировано 2026-05-24, аудит 2026-05-25):**

| Канал | `CashShift` | `cash_shift_id` |
|-------|-------------|-----------------|
| Shop `/shop/api/orders` | не требуется | **NULL** |
| Киоск (будущий, тот же API) | не требуется | **NULL** |
| Barista POS `POST /barista/orders` | **обязательна open** | **обязателен** |
| Barista `update_status` / `cancel` | **обязательна open** | — |

**Веха 2:** единый запрет заказа без смены на **всех** каналах — см. `qa_scenarios.md` [ВЕХА 2] 3.V2-1.

---

## Реестр входов (сквозной аудит)

| # | Вход | Файл | Смена В1 | Тест |
|---|------|------|----------|------|
| 1 | Shop checkout | `app/services/shop/order_creator.rb` | не проверяется, `cash_shift_id` не задаётся | `block_g#test_shop_order_succeeds_without_cash_shift` |
| 2 | Shop API controller | `app/controllers/shop/api/orders_controller.rb` | делегирует OrderCreator | `test/integration/shop/` |
| 3 | Barista create | `app/services/barista/order_creation_service.rb` | `shift.open?` → иначе ошибка | `block_g#test_barista_order_requires_open_shift` |
| 4 | Barista create (controller) | `app/controllers/barista/orders_controller.rb#create` | `current_shift` guard | `block_g#test_barista_cannot_create_order_when_shift_closed` |
| 5 | Barista update_status | `app/controllers/barista/orders_controller.rb#update_status` | `current_shift` guard | `block_g#test_barista_cannot_update_order_status_without_open_shift` |
| 6 | Barista cancel | `app/controllers/barista/orders_controller.rb#cancel` + `OrderCancellationService` | `current_shift` + reason → audit | `block_g` cancel tests |
| 7 | Manager POS create | — | **нет** в В1 | — |
| 8 | Payment callback → status | `Callbacks::PaymentStatusUpdater` | не создаёт Order | — |

**Итог аудита 2026-05-25:** все существующие входы В1 соответствуют гибриду; новых обходов нет.

---

## Gate (чтобы не повторялось)

1. **Новый вход заказа** → строка в таблице выше + тест + строка в [`CHECKLIST.md`](CHECKLIST.md) §G.
2. **Закрытие блока G** → `[x]` только если эта таблица актуальна и `block_g_cash_shift_test` зелёный.
3. **Таск-трекер (In Progress)** → не «Done», пока в чеклисте нет `[x]` на «аудит входов» и «решение A/B».

**Связанные доки:** [`../checklists/CHECKLIST.md`](../checklists/CHECKLIST.md) §G, [`PRACTICES.md`](PRACTICES.md) § Gate, [`../qa/QA_ACCEPTANCE_RUN.md`](../qa/QA_ACCEPTANCE_RUN.md).
