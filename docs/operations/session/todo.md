# todo — #72 Receipt.Email / Phone для фискальных чеков

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 0 intake `750b488c` | **SPEC ready** | `/sbr` → RED |

**CBR:** #72  
**ТЗ:** [`customer_tasks/Доработка бэкенда — передача email покупателя в Receipt для фискальных чеков.md`](../milestones/veha_2/requirements/customer_tasks/Доработка%20бэкенда%20—%20передача%20email%20покупателя%20в%20Receipt%20для%20фискальных%20чеков.md)  
**Артефакты:** [`artifacts/receipt_email_fiscal_checks/`](../milestones/veha_2/artifacts/receipt_email_fiscal_checks/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** security review · задача 1 из 5. Не ломать Callcheck/#71, ОФД-состав Items, Cancel #40.

## Цель (1 предложение)

Во всех Init (и Cancel/закрытии, если формируют Receipt) передавать контакт покупателя в `Receipt.Email` (приоритет) или `Receipt.Phone` из доверенных данных заказа/`MobileCustomer`; отправку чека делает касса Т-Банк, не наш mailer.

## Gap (код vs ТЗ)

| Есть | Не закрыто / дыра |
|------|-------------------|
| `Payments::TbankReceiptBuilder` — Email **и** Phone в API | Callers почти всегда передают только `email:`; **нет приоритета Email>Phone** (сейчас кладёт оба, если оба переданы) |
| SBP Init / SBP autopay — Receipt в Init | **Card/widget/new_card/OrderCreator Init — без Receipt** |
| Confirm — без Receipt (`TbankAdapter#confirm_payment`) | Зафиксировать как **ожидаемое** (не баг) |
| Cancel полный — без Receipt (#40) | Partial Cancel + Receipt — **нет** в продукте |
| `PaymentMethod=full_payment` only | `SendClosingReceipt` / prepayment/advance — **NOT FOUND** |
| Контакт: `mobile_customers.email/phone`; `order_emails` = свой mailer (#71) | Не путать `OrderEmail` / `SendOrderReceiptEmailJob` с ОФД Receipt |
| Checkout: identity = Callcheck phone (#71) | Email-гейт на pay **не возвращать**; phone уже закрывает «email или phone» |

## Решения SPEC (open → closed для BUILD)

| Вопрос | Решение |
|--------|---------|
| Confirm + Receipt? | **Нет** — Confirm не формирует Receipt; документировать в `tbank.md` / INTEGRATIONS |
| Полный Cancel без Receipt? | **Оставить** (#40): касса формирует чек возврата по исходному платежу; документировать |
| Partial Cancel + Receipt? | **Вне slice 1**, если нет готового partial Cancel API — backlog / отдельный шаг после доказательства необходимости |
| SendClosingReceipt? | **SKIP в коде**: в продукте только `full_payment`; нет prepayment/advance. Документировать open→closed: «триггер N/A до появления предоплаты» |
| Checkout email обязателен? | **Нет**, если есть verified phone (Callcheck). Обязателен контакт для Init: phone и/или valid email с `MobileCustomer` (или сохранённый order email только если явно связан с заказом — приоритет customer) |
| Где валидация email перед Init? | В builder / тонком resolver **до** `init_payment`; невалидный email → Error, запрос в Т-Банк не уходит |
| Схема БД? | **Не трогать** — контакт уже на `mobile_customers` |

## Acceptance (DoD) — slice 1

1. `TbankReceiptBuilder`: при email+phone → только `Receipt.Email` (Phone не дублировать); при отсутствии email → `Receipt.Phone`; при отсутствии обоих → Error до Init.
2. Невалидный email → Error; Init не вызывается.
3. Все актуальные Init-пути витрины передают Receipt (SBP + card/widget/new_card + OrderCreator gateway Init + SBP autopay).
4. Confirm без Receipt — явно в docs/тестах как ожидаемое.
5. Полный Cancel без Receipt — docs + существующий тест adapter; partial/SendClosing — documented SKIP.
6. Не ломать #71 mailer / Callcheck / состав Items.
7. Тесты Minitest (не `npm test`/`tsc` из ТЗ) + bridge в `docs/integrations/tbank.md`.

## Фазы SBR

- [x] PHASE 0 intake (`750b488c`)
- [x] PHASE 1 SPEC
- [ ] RED — builder policy + Init callers без контакта / с приоритетом
- [ ] GREEN
- [ ] /regress (зона оплаты)
- [ ] REVIEW (bugbot+security · Entire · push/CI)

## Файлы (ожидаемо)

- `app/services/payments/tbank_receipt_builder.rb` — политика Email>Phone, валидация, отказ без контакта
- `app/services/shop/sbp_payment_initiator.rb` — передавать email **и** phone с customer в builder
- `app/services/shop/sbp_autopay_charge_service.rb` — то же для autopay Init
- `app/services/shop/order_creator.rb` — `init_gateway_payment!` + Receipt (сейчас без)
- `app/services/shop/widget_payment_initiator.rb` — Init + Receipt
- `app/services/shop/new_card_payment_service.rb` — Init + Receipt
- `docs/integrations/tbank.md` — Receipt policy, Confirm/Cancel/SendClosing decisions

### Blast-radius (+3)

- `app/services/payments/tbank_adapter.rb` — Init уже принимает `receipt:`; Confirm/Cancel не расширять в slice 1 (почему: #40 + Confirm без Receipt)
- `test/services/payments/tbank_receipt_builder_test.rb` · `tbank_adapter_test.rb` · `sbp_payment_initiator_test.rb` — зеркала RED/GREEN
- `app/frontend/routes/Checkout.svelte` — **только audit**: не возвращать email-гейт; при необходимости убедиться что phone/email уходят в create order (почему: Subtask 1–4 vs #71)

## Не ломать

- Callcheck / phone identity / `#71` post-pay email mailer (`Orders::EmailService`, `order_emails`)
- Состав Receipt Items / Taxation / Token (Receipt вне Token)
- Полный guest Cancel #40 и платёжный статус webhook
- История заказов / ЛК чеки (следующая задача серии — вне scope)

## Проверка

- `bin/rails test test/services/payments/tbank_receipt_builder_test.rb test/services/payments/tbank_adapter_test.rb test/services/shop/sbp_payment_initiator_test.rb`
- `bin/rails test test/services/shop/order_creator_test.rb test/integration/shop/api/qa_section_2_3_payment_cart_test.rb`

## Канон тестов

Minitest `test/` · **не** `npm test` / `npx tsc` из формулировки ТЗ (в репо канон Rails+`node --test` для JS; эта задача — backend Receipt).
