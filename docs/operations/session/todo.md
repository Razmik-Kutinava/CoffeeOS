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

- [x] **SPEC** (`b9d80b99`)
- [x] **RED** (`14b968dd`)
- [x] **GREEN** (`5b3bc76e`)
- [x] **/regress** — JS 54/0 · rails 15/0
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | `beginSbpBankRedirect`: pending LS + `#/payment-result?status=waiting` до nspk |
| 2 | `createSbpAutopayFsm` + `resolveSbpAutopaySheetError` — не card `payFsmLabel` |
| 3 | App recover — без дельты |
| 4 | **Вне slice:** SMS; greenfield CODE:BLACK |

## Файлы (ожидаемо)

- `app/frontend/routes/Checkout.svelte`
- `app/frontend/lib/shopSbpPay.js` — `beginSbpBankRedirect`
- `app/frontend/lib/shopSbpAutopay.js` — `resolveSbpAutopaySheetError`
- `app/frontend/App.svelte` / `PaymentResult.svelte` / `codeblackPendingOrder.js` — без дельты GREEN

### Blast-radius (+2)

- `shopPayFsm.js` — card path не трогали
- `PaymentMethodsSheet.svelte` — без дельты

## Не ломать

- Card One-Click / 3DS / `payFsmLabel`
- Repeat SBP
- #35 шторка
- Webhook / AccountToken bind

## Проверка

- `node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs test/javascript/shop_sbp_autopay_test.mjs test/javascript/shop_sbp_autopay_checkout_ui_test.mjs`
- `bin/rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/api/sbp_autopay_charge_test.rb test/integration/shop/api/payment_status_test.rb`

## Local GREEN

- JS: 54/0 PASS
- rails zone (return_ui + charge + status): **15 runs / 70 assertions / 0 fail** PASS (`bundle exec rails test …`)
