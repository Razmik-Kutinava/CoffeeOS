# todo — #79 SBP return + autopay labels (остаток CODE:BLACK)

| Поле | Значение |
|------|----------|
| **CBR** | #79 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Надписи%20автоплатежа%20и%20экран%20после%20возврата%20из%20банка%20СБП.md) |
| **Тип** | Fix / hot-path оплата · PWA return + SBP autopay UI |
| **Цель** | После банка — ясный экран (WAITING/ok/fail); надписи автоплатежа по ответу банка |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/sbp_return_status_screen_autopay_labels/`](../milestones/veha_2/artifacts/sbp_return_status_screen_autopay_labels/) |

## SBR

- [x] **SPEC**
- [x] **RED** (`14b968dd`)
- [x] **GREEN** (`5b3bc76e`)
- [x] **/regress** — JS 54/0 · rails 15/0
- [x] **REVIEW** — bugbot fixes · security OK · push pending

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | `beginSbpBankRedirect`: pending + sync `location.hash` waiting + nspk |
| 2 | `resolveSbpAutopaySheetError` · init fail без rethrow в card FSM |
| 3 | App recover: poll на waiting; skip только ok/fail/success |
| 4 | **Вне slice:** SMS |

## Не ломать

- Card One-Click / 3DS
- Repeat SBP
- #35 шторка
- Webhook / AccountToken

## Проверка

- `node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs test/javascript/shop_sbp_autopay_test.mjs test/javascript/shop_sbp_autopay_checkout_ui_test.mjs`
- `bundle exec rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/api/sbp_autopay_charge_test.rb test/integration/shop/api/payment_status_test.rb`
