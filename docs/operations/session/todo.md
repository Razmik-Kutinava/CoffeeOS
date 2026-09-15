# todo — #86 SBP PWA recovery after bank (EXT)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#86** |
| **Тип** | SBR · EXT CODE:BLACK |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-86-Восстановление PWA после оплаты СБП-EXT.md`](../milestones/veha_2/requirements/customer_tasks/TASK-86-Восстановление%20PWA%20после%20оплаты%20СБП-EXT.md) |
| **Google** | https://docs.google.com/document/d/1i12UGabEH3UJQrR9y7tQS9ONZMvOxG_ARCg3bKcdDoU/edit?usp=drivesdk |
| **Артефакты** | [`sbp_pwa_recovery_after_bank_ext/`](../milestones/veha_2/artifacts/sbp_pwa_recovery_after_bank_ext/) |
| **OUT** | надписи автоплатежа / 11·8 СБП → #79 · SMS-ссылка → каскад (отдельная задача) |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec` — канон в этом todo
- [ ] PHASE 2 RED — падающие тесты recovery (TTL/race/CONFIRMED…/cold start)
- [ ] PHASE 2 GREEN — реализация + регрессия зоны
- [ ] PHASE 3 `/review` — bugbot + security · push · device Android/iOS без SKIP · Entire

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/lib/codeblackPendingOrder.js` | pending LS · TTL · clear · race guard |
| `app/frontend/App.svelte` | lifecycle recovery (pageshow / visibility / cold start) → status → UI |
| `app/frontend/lib/shopSbpPay.js` | save pending до redirect · `checkOrderStatus` · WAITING_FOR_BANK |
| `app/frontend/routes/PaymentResult.svelte` | waiting / success / error / «Я оплатил» |
| `test/javascript/codeblack_pending_order_test.mjs` | unit pending + guard (расширить под gap) |
| `test/javascript/shop_sbp_pay_test.mjs` | unit SBP status / recovery mapping |
| `test/integration/shop/sbp_payment_return_ui_test.rb` | wire PaymentResult + recovery contracts |

**Blast-radius (+соседи, только если RED/device покажет дыру):**

| Path | Почему |
|------|--------|
| `app/frontend/routes/Checkout.svelte` | старт SBP flow — не трогать card/Rebill, только если pending не сохраняется до ухода |
| `app/frontend/lib/shopGuestSession.js` | ownership после cold start — не ломать guest reconnect |
| `app/controllers/shop/api/payments_controller.rb` | `GET status` — только при доказанном ownership/status ограничении |

## Не ломать

1. Card / Rebill / Charge flow и токенизация.
2. Webhook Т-Кассы · `/payments/sbp/init` · бизнес-семантика CONFIRMED/REJECTED/CANCELED.
3. OrderStatusSheet / active orders · CartSheet · Product visibility polling.
4. Guest session reconnect (кроме минимально нужного для SBP order ownership).

## Проверка

```bash
node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs
bin/rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/sbp_payment_ui_test.rb
```

**После GREEN / Review:** device E2E Android + iOS (PWA → NSPK → bank → return/reopen → result) без SKIP → артефакты в `artifacts/sbp_pwa_recovery_after_bank_ext/device/`. Fly MCP Point A — на Review.

## DoD (из ТЗ)

- [ ] Unit/integration зелёные; race guard; TTL; terminal clear
- [ ] Recovery после return + cold start; PENDING ≠ ложный отказ; сеть ≠ terminal
- [ ] Device Android + iOS без SKIP; platform-diff задокументирован
- [ ] Card/Rebill / guest reconnect / webhook не сломаны
- [ ] Review + решение A/B/C/D (общий vs platform-specific)
- [ ] COMPONENT_MAP — только после зелёного Review
