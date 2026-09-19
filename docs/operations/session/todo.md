# todo — Патч 1: inline-оплата · статусы внутри кнопки

| Поле | Значение |
|------|----------|
| **ID** | **Патч 1** · 2026-09-17 · patch v1 |
| **Тип** | SBR · патч · hot-path shop pay (Quick Repeat button) |
| **Статус** | **REVIEW · CI green** · deploy апрув |
| **Ветка** | `develop` |
| **ТЗ** | [`Интеграция inline-оплаты Т-Банка с динамическими статусами внутри кнопки.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md) · секция **Патч 1: 2026-09-17** → **Исправленный сценарий** |
| **GATES** | JS/Rails patch1 + FSM · Local PASS 2026-09-19 · Fly MCP после deploy |
| **Google Doc** | https://docs.google.com/document/d/16mYs8tQLg7r1sm7XBmWxRS8ON1kngU4cHIh4EdrKVEY/edit |

## SBR

- [x] PHASE 0 /start (аудит vs Google Doc / customer_tasks)
- [x] PHASE 1 SPEC — только Исправленный сценарий (Subtask 8/10/12/13 patch v1)
- [x] PHASE 2 RED — `widget_repeat_pay_flow_patch1` + `inline_pay_button_patch1` [TDD]
- [x] PHASE 2 GREEN — статусы в `shop-repeat-card-pay` · 1051 short · ERROR/timeout → IDLE 3000 мс
- [x] `/regress` (Проверка) · Local PASS 2026-09-19 (reverify)
- [x] PHASE 3 `/review` — CI green · deploy апрув

## Файлы (ожидаемо)

1. `app/frontend/lib/shopInlinePayFsm.js` — ротация 1800 · poll 1500 · timeout 15000 · 1051 / «Ошибка оплаты» · `TBANK_INLINE_ERROR_RESET_MS=3000`
2. `app/frontend/lib/widgetRepeatPayFlow.js` — `resetAfterMs` на REJECTED/CANCELED/timeout/http_error; retry/fallback UI
3. `app/frontend/components/RepeatSection.svelte` — `cardPayLabel` / цвет кнопки · `statusInHostButton` · `payResetTimer` → IDLE
4. `app/frontend/components/InlinePayFallback.svelte` — `statusInHostButton` скрывает дубль status bar
5. `test/javascript/widget_repeat_pay_flow_patch1_test.mjs` — G1 labels/UI/reset
6. `test/javascript/shop_inline_pay_button_fsm_test.mjs` — intervals + cycle
7. `test/integration/shop/inline_pay_button_patch1_test.rb` — source-contract patch1

### Blast-radius (соседи, не менять)

- `Checkout.svelte` / `PaymentMethodsSheet.svelte` — стандартный checkout
- `CartSheet.svelte` / `cartSheetStore.js` — clearCart / граница QR
- `OrderStatusSheet` / `/orders/active`
- `Profile.svelte` / `OrderReceipt.svelte` / `historyRepeatAdapter.js` — TASK_94 / ЛК
- payment API · `widget_init` · Charge · webhook

## Не ломать

1. Стандартный checkout / payment API (`widget_init`, status, Charge, webhook)
2. Quick Repeat orchestration как отдельную фичу (только UI/state статусов кнопки)
3. `cartSheetStore.clearCartAfterSuccessfulPay` (#87)
4. `OrderStatusSheet` / active-order · Profile/OrderReceipt (TASK_94)

## Проверка

```bash
node --test test/javascript/widget_repeat_pay_flow_patch1_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs
bundle exec rails test test/integration/shop/inline_pay_button_patch1_test.rb test/integration/shop/quick_repeat_pay_one_click_test.rb
```

## DoD

- [x] Subtask 8 (patch v1): PROCESSING + «Ещё чуть-чуть...» **внутри** `shop-repeat-card-pay`
- [x] Subtask 10 (patch v1): ротация 1800 мс внутри кнопки · poll 1500 мс
- [x] Subtask 12 (patch v1): 1051 → «Недостаточно средств»; иначе «Ошибка оплаты»; ERROR→IDLE 3000 мс
- [x] Subtask 13 (patch v1): timeout 15000 → «Время ожидания истекло»; → IDLE 3000 мс
- [x] Subtask 12/13: retry / СБП / «карта +» сохранены; payment API не меняли
- [ ] Fly MCP Point A после deploy (апрув)
- [ ] `COMPONENT_MAP.md` — только если Review потребует смены строки (зона уже отражена)
