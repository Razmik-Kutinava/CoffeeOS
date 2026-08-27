# todo — #72 Receipt.Email / Phone для фискальных чеков

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN `5f68efea` | **GREEN done** · Entire `01M11269FD48FXF42NCW98AG0X` | `/regress` |

**CBR:** #72  
**ТЗ:** [`customer_tasks/Доработка бэкенда — передача email покупателя в Receipt для фискальных чеков.md`](../milestones/veha_2/requirements/customer_tasks/Доработка%20бэкенда%20—%20передача%20email%20покупателя%20в%20Receipt%20для%20фискальных%20чеков.md)  
**Артефакты:** [`artifacts/receipt_email_fiscal_checks/`](../milestones/veha_2/artifacts/receipt_email_fiscal_checks/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** security review · задача 1 из 5. Не ломать Callcheck/#71, ОФД-состав Items, Cancel #40.

## Цель (1 предложение)

Во всех Init (и Cancel/закрытии, если формируют Receipt) передавать контакт покупателя в `Receipt.Email` (приоритет) или `Receipt.Phone` из доверенных данных заказа/`MobileCustomer`; отправку чека делает касса Т-Банк, не наш mailer.

## Gap (код vs ТЗ) — закрыто в GREEN

| Было | Стало |
|------|-------|
| Callers только `email:` / оба ключа | `for_order!` · Email>Phone · валидация |
| Card/widget/new_card Init без Receipt | Receipt на всех Init (+ `charge_recurrent`, InlineInit) |
| Confirm / Cancel / SendClosing | docs: Confirm/Cancel без Receipt; SendClosing N/A |

## Фазы SBR

- [x] PHASE 0 intake (`750b488c`)
- [x] PHASE 1 SPEC (`d99894dc`)
- [x] RED (`d138c116`)
- [x] GREEN (`5f68efea`)
- [ ] /regress (зона оплаты)
- [ ] REVIEW (bugbot+security · Entire · push/CI)

## Файлы (ожидаемо)

- `app/services/payments/tbank_receipt_builder.rb` — политика Email>Phone, валидация, отказ без контакта
- `app/services/shop/sbp_payment_initiator.rb` — `for_order!`
- `app/services/shop/sbp_autopay_charge_service.rb` — то же
- `app/services/shop/order_creator.rb` — Init + Receipt
- `app/services/shop/widget_payment_initiator.rb` — Init + Receipt
- `app/services/shop/new_card_payment_service.rb` — Init + Receipt
- `docs/integrations/tbank.md` — Receipt policy

### Blast-radius (+3)

- `app/services/payments/tbank_adapter.rb` — `charge_recurrent` + Receipt
- `app/services/payments/tbank_inline_init.rb` — widget Init + Receipt
- зеркала тестов builder / sbp / widget / inline / adapter

## Не ломать

- Callcheck / phone identity / `#71` post-pay email mailer (`Orders::EmailService`, `order_emails`)
- Состав Receipt Items / Taxation / Token (Receipt вне Token)
- Полный guest Cancel #40 и платёжный статус webhook
- История заказов / ЛК чеки (следующая задача серии — вне scope)

## Проверка

- `bin/rails test test/services/payments/tbank_receipt_builder_test.rb test/services/payments/tbank_adapter_test.rb test/services/shop/sbp_payment_initiator_test.rb`
- `bin/rails test test/services/shop/order_creator_test.rb test/integration/shop/api/qa_section_2_3_payment_cart_test.rb`
