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
- [ ] **RED**
- [ ] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | Перед `redirectToSbp` — `savePendingOrder` + переход на `#/payment-result?status=waiting` (явный экран до ухода в банк; Android return не «пустой») |
| 2 | Автоплатёж СБП: wire `createSbpAutopayFsm` / `SBP_AUTOPAY_TOASTS` + `mapSbpAutopayError`; не подменять card-`payFsmLabel` («Обработка банком…») на decline/network/service |
| 3 | `visibilitychange` / cold start в `App.svelte` — оставить; усилить тестами recover → waiting/ok/fail |
| 4 | **Вне slice:** SMS со ссылкой на гл. экран (гипотеза заказчика → backlog); greenfield Init/GetQr из повторного CODE:BLACK ТЗ (уже есть) |

## Файлы (ожидаемо)

- `app/frontend/routes/Checkout.svelte` — SBP/autopay pay: pending + waiting route до redirect; labels ошибок ChargeQr
- `app/frontend/App.svelte` — `recoverCodeblackPendingOrder` (visibility + cold start)
- `app/frontend/routes/PaymentResult.svelte` — WAITING_FOR_BANK + «Я оплатил»
- `app/frontend/lib/shopSbpAutopay.js` — FSM + `SBP_AUTOPAY_TOASTS` / `mapSbpAutopayError`
- `app/frontend/lib/shopSbpPay.js` — `checkOrderStatus`, waiting copy, `redirectToSbp`
- `app/frontend/lib/codeblackPendingOrder.js` — LS `codeblack_pending_order`, TTL 15 мин, visibility guard

### Blast-radius (+2)

- `app/frontend/lib/shopPayFsm.js` — сейчас смешивается с SBP errors через `fsmFromPaymentError` / `resolveCheckoutSheetInlineError`
- `app/frontend/components/PaymentMethodsSheet.svelte` — CTA/labels `sbp` / `sbp_account`

## Не ломать

- Оплата картой One-Click / 3DS / `payFsmLabel` для card
- «Повторить» + init SBP из `RepeatSection` (pending+redirect path)
- Статусная шторка / peek CartSheet (#35)
- Webhook Т‑Кассы → `accepted` / AccountToken bind

## Проверка

- `node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs test/javascript/shop_sbp_autopay_test.mjs test/javascript/shop_sbp_autopay_checkout_ui_test.mjs`
- `bin/rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/api/sbp_autopay_charge_test.rb test/integration/shop/api/payment_status_test.rb`

## Проверка (после deploy)

- Fly MCP Point A: SBP 11₽/8₽ · return → waiting/ok · autopay decline/success copy · Android (+ iOS если устройство)
- SMS-гипотеза — **не** в DoD этого slice

## Зеркальные тесты (ожидаемо RED)

- `test/javascript/codeblack_pending_order_test.mjs` — дописать: recover path / waiting before redirect contract
- `test/javascript/shop_sbp_autopay_checkout_ui_test.mjs` — FSM wired; bank response → autopay toasts, не card FSM
- `test/integration/shop/sbp_payment_return_ui_test.rb` — Checkout пишет waiting hash / pending до redirect
