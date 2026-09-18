# todo — Патч 1: inline-оплата Т‑Банка — статусы в кнопке

| Поле | Значение |
|------|----------|
| **ID** | Inline T‑Bank · **Патч 1** (2026-09-17) |
| **Тип** | SBR · patch · hot-path shop pay UI |
| **Статус** | **GREEN** · Next: `/review` |
| **Ветка** | `develop` |
| **ТЗ** | [`Интеграция inline-оплаты Т-Банка…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md) · секция **Патч 1** |
| **Цель** | Subtask 8/10/12/13 (patch v1): PROCESSING/ротация **внутри** `shop-repeat-card-pay`; 1051→«Недостаточно средств»; ERROR/timeout → IDLE через 3000 мс |

## SBR

- [x] PHASE 0 /start (чат)
- [x] PHASE 1 SPEC — этот файл
- [x] PHASE 2 RED — failing tests `[RED]` · `ddd04998`
- [x] PHASE 2 GREEN — UI/FSM/flow `[GREEN]`
- [x] `/regress` — § Проверка (JS 25/25 · Rails patch1 4/4 · quick_repeat_pay)
- [ ] PHASE 3 `/review` — bugbot + security · push

## Файлы (ожидаемо)

- `app/frontend/lib/shopInlinePayFsm.js` — labels 1051 / «Ошибка оплаты» / ротация «от банка»
- `app/frontend/lib/widgetRepeatPayFlow.js` — timeout label + `resetAfterMs` на ERROR/timeout
- `app/frontend/components/RepeatSection.svelte` — статус внутри `shop-repeat-card-pay` (`cardPayLabel`)
- `app/frontend/components/InlinePayFallback.svelte` — `statusInHostButton` без дубля bar
- `test/javascript/shop_inline_pay_button_fsm_test.mjs`
- `test/javascript/payment_error_user_messages_test.mjs`
- `test/javascript/widget_repeat_pay_flow_patch1_test.mjs`
- `test/integration/shop/inline_pay_button_patch1_test.rb`

## Не ломать

1. `cartSheetStore.clearCartAfterSuccessfulPay` (#87) — не менять семантику
2. Стандартный checkout / `Checkout.svelte` / `shopPayFsm` long CARD_MSG
3. CartSheet / OrderStatusSheet / active-order contour (COMPONENT_MAP)
4. Fallback СБП / «карта +» / retry после отказа; widget_init / Charge / webhook API

## Проверка

```bash
node --test test/javascript/shop_inline_pay_button_fsm_test.mjs test/javascript/payment_error_user_messages_test.mjs test/javascript/widget_repeat_pay_flow_fallback_ui_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs
bundle exec ruby -Itest test/integration/shop/inline_pay_button_patch1_test.rb test/integration/shop/quick_repeat_pay_one_click_test.rb
```

**Local:** JS **25/25 PASS** · Rails patch1 **4/4 PASS** · quick_repeat_pay one-click regress

## DoD

- [x] Subtask 8 (patch v1): PROCESSING + «Ещё чуть-чуть...» внутри главной pay-кнопки
- [x] Subtask 10 (patch v1): ротация 1800 мс в кнопке; poll 1500 мс
- [x] Subtask 12 (patch v1): 1051 → «Недостаточно средств»; иначе → «Ошибка оплаты»; ERROR→IDLE 3000 мс
- [x] Subtask 13 (patch v1): timeout 15000 → красная кнопка + label; →IDLE 3000 мс
- [x] retry / другая карта / fallback сохранены
- [x] targeted + regress зелёные
- [ ] Review + COMPONENT_MAP (после `/review`)
