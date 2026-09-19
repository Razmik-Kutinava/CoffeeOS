# todo — Патч 1: inline-оплата Т‑Банка — статусы в кнопке

| Поле | Значение |
|------|----------|
| **ID** | Inline T‑Bank · **Патч 1** (2026-09-17) |
| **Тип** | SBR · patch · hot-path shop pay UI |
| **Статус** | **REVIEW** · push/CI |
| **Ветка** | `develop` |
| **ТЗ** | [`Интеграция inline-оплаты Т-Банка…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md) · секция **Патч 1** |
| **Entire** | `01M2WC1SCBV10YQZW2HFQ6DNM7` на `9eab6800` |

## SBR

- [x] PHASE 0 /start
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED `ddd04998`
- [x] PHASE 2 GREEN `9e0a295c`
- [x] `/regress` Local PASS
- [x] PHASE 3 `/review` — bugbot (timer fix) + security clean · Entire · push

## Файлы

- `app/frontend/lib/shopInlinePayFsm.js`
- `app/frontend/lib/widgetRepeatPayFlow.js`
- `app/frontend/components/RepeatSection.svelte` (+ `clearPayResetTimer`)
- `app/frontend/components/InlinePayFallback.svelte`
- tests: `shop_inline_pay_button_fsm_test.mjs`, `payment_error_user_messages_test.mjs`, `widget_repeat_pay_flow_patch1_test.mjs`, `inline_pay_button_patch1_test.rb`

## Не ломать

1. `clearCartAfterSuccessfulPay` (#87)
2. checkout / `shopPayFsm` long CARD_MSG
3. CartSheet / OrderStatusSheet / active-order
4. Fallback СБП / «карта +» / retry; payment API

## Проверка

```bash
node --test test/javascript/shop_inline_pay_button_fsm_test.mjs test/javascript/payment_error_user_messages_test.mjs test/javascript/widget_repeat_pay_flow_fallback_ui_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs
bundle exec ruby -Itest test/integration/shop/inline_pay_button_patch1_test.rb test/integration/shop/quick_repeat_pay_one_click_test.rb
```

## DoD

- [x] Subtask 8/10/12/13 patch v1
- [x] retry/fallback сохранены
- [x] bugbot hole closed (`payResetTimer`)
- [x] Entire id на sha
- [ ] CI green (после push)
- [ ] COMPONENT_MAP — не главная задача зоны → не трогали
