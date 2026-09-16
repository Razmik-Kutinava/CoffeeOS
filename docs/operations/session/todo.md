# todo — #90 TASK_89-POSTCALL-EXT return after Callcheck → pay

| Поле | Значение |
|------|----------|
| **ID** | CBR **#90** (Google: TASK_89-POSTCALL-EXT) |
| **Статус** | **unlazy** 2026-09-16 · restart после rollback · ждёт `/spec` → `/sbr` |
| **ТЗ** | [`TASK-89-POSTCALL-EXT-…md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-POSTCALL-EXT-Возврат%20в%20PWA%20после%20Callcheck%20и%20продолжение%20оплаты.md) |
| **Google** | https://docs.google.com/document/d/1w2VKMPaYZdsJcqNkLrpSbJBPuLE-7Sm9giQ8DcJ0Bq0/edit?usp=drivesdk |
| **Артефакты** | [`pwa_callcheck_return_continue_payment/`](../milestones/veha_2/artifacts/pwa_callcheck_return_continue_payment/) |
| **GATES** | [`GATES.md`](GATES.md) |

## Не ломать

- #89 Callcheck / SMS / linker / session backend
- #91 UI-EXT (phone CTA/cart hide / sheet thickness)
- сумма / состав заказа / cart state
- PaymentMethodsSheet UI (только авто-open после auth)

## Проверка

- G1: `node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_auth_wizard_test.mjs`
- G2: `ruby bin/rails test test/integration/shop/silent_refresh_frontend_structural_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb`
- G3: `ruby bin/rails test test/integration/shop/api/phone_otp_test.rb test/services/shop/phone_verified_customer_linker_test.rb test/services/shop/phone_otp_test.rb`
- G4: `node --test test/javascript/phone_otp_ui_test.mjs test/javascript/shop_phone_auth_cascade_smsru_test.mjs`
- G5: Fly MCP Point A после deploy (manual)

## SBR

- [x] PHASE 0 intake (сохранён; restart)
- [ ] PHASE 1 `/spec`
- [ ] PHASE 2 RED/GREEN
- [ ] PHASE 3 `/review`

## Next

`/spec` → `/sbr`
