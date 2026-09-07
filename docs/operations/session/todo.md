# todo — #79 SBP return + autopay labels (остаток CODE:BLACK)

| Поле | Значение |
|------|----------|
| **CBR** | #79 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Надписи%20автоплатежа%20и%20экран%20после%20возврата%20из%20банка%20СБП.md) |
| **Тип** | Fix / hot-path оплата · PWA return + SBP autopay UI |
| **Цель** | После банка — ясный экран (WAITING/ok/fail); надписи автоплатежа по ответу банка; регресс 11/8 СБП |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/sbp_return_status_screen_autopay_labels/`](../milestones/veha_2/artifacts/sbp_return_status_screen_autopay_labels/) |

## SBR

- [x] **SPEC**
- [x] **RED** (`14b968dd`)
- [x] **GREEN** (pending commit)
- [ ] **/regress**
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | `beginSbpBankRedirect`: pending LS + `#/payment-result?status=waiting` до nspk |
| 2 | `createSbpAutopayFsm` + `resolveSbpAutopaySheetError` — не card `payFsmLabel` |
| 3 | App recover visibility/cold start — без изменений (уже есть) |
| 4 | **Вне slice:** SMS; greenfield CODE:BLACK |

## Файлы (ожидаемо)

- `app/frontend/routes/Checkout.svelte` — wired
- `app/frontend/lib/shopSbpPay.js` — `beginSbpBankRedirect`
- `app/frontend/lib/shopSbpAutopay.js` — `resolveSbpAutopaySheetError`
- `app/frontend/App.svelte` — recover (без дельты)
- `app/frontend/routes/PaymentResult.svelte` — WAITING (без дельты)
- `app/frontend/lib/codeblackPendingOrder.js` — LS (без дельты)

### Blast-radius (+2)

- `app/frontend/lib/shopPayFsm.js` — card path не трогали
- `app/frontend/components/PaymentMethodsSheet.svelte` — без дельты

## Не ломать

- Оплата картой One-Click / 3DS / `payFsmLabel` для card
- «Повторить» + init SBP из `RepeatSection`
- Статусная шторка / peek CartSheet (#35)
- Webhook Т‑Кассы → `accepted` / AccountToken bind

## Проверка

- `node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs test/javascript/shop_sbp_autopay_test.mjs test/javascript/shop_sbp_autopay_checkout_ui_test.mjs`
- `bin/rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/api/sbp_autopay_charge_test.rb test/integration/shop/api/payment_status_test.rb`
