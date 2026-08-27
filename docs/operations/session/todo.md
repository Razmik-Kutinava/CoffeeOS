# todo — #73 Хранение и отображение фискальных чеков в ЛК

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| REVIEW + push | CI | deploy апрув · Fly MCP |

**CBR:** #73  
**ТЗ:** [`customer_tasks/Хранение и отображение фискальных чеков в личном кабинете.md`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md)  
**Артефакты:** [`artifacts/fiscal_receipts_personal_cabinet/`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/) · SCHEMA.md  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

## Цель

Идемпотентно принимать `Status=RECEIPT` от Т-Банка, сохранять в `fiscal_receipts`, отдавать в `order_json`, показывать секцию «Чек» в `OrderReceipt.svelte`.

## Фазы SBR

- [x] PHASE 0 intake (`fb5334d8`)
- [x] PHASE 1 SPEC (`ec76fa02`)
- [x] RED (`579f9468`)
- [x] GREEN (`8e923305`) · Entire `01M11269FD48FXF42NCW98AG0X`
- [x] /regress (46+3+6)
- [x] REVIEW (bugbot `fiscal_expected` · security clean · push/CI)

## Проверка

```bash
bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/api/pwa_lk_api_test.rb
bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb test/integration/shop/api/order_fiscal_receipts_api_test.rb
```

## Ops вне кода

- Subtask 3: включить fiscal notifications в кабинете терминала Т-Банка (владелец)
- Fly MCP Point A после deploy
