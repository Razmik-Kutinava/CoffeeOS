# todo — #73 Хранение и отображение фискальных чеков в ЛК

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 1 SPEC | пути + gap + блокеры в todo | `/sbr` RED (после схемы payload или stub-контракт) |

**CBR:** #73  
**ТЗ:** [`customer_tasks/Хранение и отображение фискальных чеков в личном кабинете.md`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md)  
**Артефакты:** [`artifacts/fiscal_receipts_personal_cabinet/`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** после #72. #72 = исходящий Receipt.Email/Phone; #73 = входящий fiscal notification + UI ЛК.

## Цель (1 предложение)

Идемпотентно принимать уведомления фискализации «Чеки Т-Бизнес», сохранять чеки (ссылка, ФН/ФД/ФП, тип) и показывать в истории/деталях заказа PWA — без своего QR и без API «запросить чек».

## Gap (код vs ТЗ)

| Сейчас | Нужно |
|--------|-------|
| `POST /callbacks/tbank` — только платёжный Status → `TbankCallbackJob` | Отличать fiscal payload и гнать в отдельный handler (тот же URL или отдельный endpoint — после схемы) |
| Ответ webhook: `JSON { ok: true }` | ТЗ: `200` + тело `OK` для fiscal; **не ломать** платёжный контракт без решения в SPEC/docs |
| `FiscalReceipt` + таблица есть; **никто в app/ не create'ит** из Т-Банка | Persist из notification: order/payment, URL, attrs, type, raw JSON; unique для идемпотентности |
| `order_json` / history — без fiscal | API отдаёт список чеков (без raw/секретов) |
| `OrderReceipt.svelte` — placeholder ОФД | Секция «Чек»: «формируется» / ссылка(и) / несколько типов |
| Legacy `POST /callbacks/fiscal_receipts` | **Не смешивать** с Т-Банк fiscal |

## Файлы (ожидаемо)

- `app/controllers/callbacks/tbank_controller.rb` — детект fiscal vs payment; Token уже здесь; enqueue/handler
- `app/services/payments/tbank_fiscal_notification_handler.rb` — **новый**: mapping PaymentId/OrderId → Payment/Order, persist, идемпотентность (зеркало mapping из `TbankCallbackJob`)
- `app/models/fiscal_receipt.rb` (+ миграция при необходимости) — unique/идемпотентность; `receipt_data` jsonb; типы payment/refund/(closing если подтвердят)
- `app/controllers/shop/api/orders_controller.rb` — `#order_json` / show: массив fiscal receipts для UI
- `app/frontend/routes/OrderReceipt.svelte` — секция «Чек» вместо OFD placeholder
- `docs/integrations/tbank.md` (+ индекс `INTEGRATIONS.md` при нужде) — контракт fiscal NotificationURL / поля / ответ

### Blast-radius (+3)

- `app/jobs/payments/tbank_callback_job.rb` — не менять семантику платёжного webhook
- `app/services/callbacks/payment_status_updater.rb` — hot-path статусов; fiscal handler не трогает
- `app/frontend/lib/shopAccountOrders.js` — клиент history/show, если контракт JSON расширяется

## Не ломать

- Платёжный webhook CONFIRMED/AUTHORIZED → accepted / RebillId / UserCards
- Checkout / Init / Cancel / возвраты (#40)
- Mapping PaymentId → `provider_payment_id` / OrderId → `orders.id`
- ЛК #69 (hub/history) вне секции чека; auth PWA

## Проверка

```bash
bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/api/pwa_lk_api_test.rb
```

Новые зеркала (ожидаемо на RED):  
`test/services/payments/tbank_fiscal_notification_handler_test.rb`  
`test/integration/shop/api/order_fiscal_receipts_api_test.rb` (или расширение `pwa_lk_api_test`)

## Open decisions (до/в RED — не угадывать payload)

1. **Схема fiscal notification** (Subtask 1) — поля URL, ФН/ФД/ФП, тип операции, idempotency key → положить пример в `artifacts/fiscal_receipts_personal_cabinet/`.
2. **Один NotificationURL** (`/callbacks/tbank` + детект) vs **отдельный endpoint** — после кабинета терминала (Subtask 3–4).
3. **Ответ Т-Банку:** plain `OK` только для fiscal / или унифицировать — зафиксировать в `tbank.md` без поломки payment регрессии.
4. **UX ссылки чека:** новая вкладка (дефолт-кандидат PWA) vs iframe — согласовать на SPEC/UI.
5. **Reuse `fiscal_receipts`:** расширить enum/unique vs новая таблица — **предпочтение reuse** + unique на внешний id в `ofd_receipt_id` / комбинации; raw JSON в `receipt_data`.

## Блокер

Без подтверждённой схемы + примера payload **запрещён** production-обработчик на предположительных полях. На RED допустимы тесты/контракт со **зафиксированным fixture**, согласованным с докой/артефактом — не выдуманные имена полей «на глаз».

## Фазы SBR

- [x] PHASE 0 intake (`fb5334d8`)
- [x] PHASE 1 SPEC (этот шаг)
- [ ] RED (`/sbr`)
- [ ] GREEN
- [ ] /regress
- [ ] REVIEW

## Out of scope (Subtask 30)

Свой QR по ФН/ФД/ФП · API кассы «чек по PaymentId» · копипаст доки Т-Банка · чужие платёжные провайдеры · Telegram/email support · PLG/рефералка.
