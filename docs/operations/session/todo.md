# todo — Патч 1: inline-оплата Т‑Банка — статусы в кнопке

| Поле | Значение |
|------|----------|
| **ID** | Inline T‑Bank · **Патч 1** (2026-09-17) |
| **Тип** | SBR · patch · hot-path shop pay UI |
| **Статус** | **BUILD** · RED→GREEN |
| **Ветка** | `develop` |
| **ТЗ** | [`Интеграция inline-оплаты Т-Банка…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md) · секция **Патч 1** |
| **Цель** | Subtask 8/10/12/13 (patch v1): PROCESSING/ротация **внутри** `shop-repeat-card-pay`; 1051→«Недостаточно средств»; ERROR/timeout → IDLE через 3000 мс |

## SBR

- [x] PHASE 0 /start (чат)
- [x] PHASE 1 SPEC — этот файл
- [ ] PHASE 2 RED — failing tests `[RED]`
- [ ] PHASE 2 GREEN — UI/FSM/flow `[GREEN]`
- [ ] `/regress` — § Проверка
- [ ] PHASE 3 `/review` — после GREEN

## Файлы (ожидаемо)

- `app/frontend/lib/shopInlinePayFsm.js` — labels 1051 / «Ошибка оплаты» / ротация «от банка»
- `app/frontend/lib/widgetRepeatPayFlow.js` — timeout label + `resetAfterMs` на ERROR/timeout
- `app/frontend/components/RepeatSection.svelte` — статус внутри `shop-repeat-card-pay`
- `app/frontend/components/InlinePayFallback.svelte` — не дублировать status bar, если хост-кнопка
- `test/javascript/shop_inline_pay_button_fsm_test.mjs` — патч-ассерты
- `test/javascript/payment_error_user_messages_test.mjs` — INLINE labels (checkout PAY_FSM не трогать)
- `test/javascript/widget_repeat_pay_flow_patch1_test.mjs` — resetAfterMs / timeout / 1051
- `test/integration/shop/inline_pay_button_patch1_test.rb` — зеркало: текст в кнопке

## Не ломать

1. `cartSheetStore.clearCartAfterSuccessfulPay` (#87) — не менять семантику
2. Стандартный checkout / `Checkout.svelte` / `shopPayFsm` long CARD_MSG
3. CartSheet / OrderStatusSheet / active-order contour (COMPONENT_MAP)
4. Fallback СБП / «карта +» / retry после отказа; widget_init / Charge / webhook API

## Проверка

```bash
node --test test/javascript/shop_inline_pay_button_fsm_test.mjs test/javascript/payment_error_user_messages_test.mjs test/javascript/widget_repeat_pay_flow_fallback_ui_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs
bin/rails test test/integration/shop/inline_pay_button_patch1_test.rb test/integration/shop/quick_repeat_pay_one_click_test.rb
```

## DoD

- [ ] Subtask 8 (patch v1): PROCESSING + «Ещё чуть-чуть...» внутри главной pay-кнопки
- [ ] Subtask 10 (patch v1): ротация 1800 мс в кнопке; poll 1500 мс
- [ ] Subtask 12 (patch v1): 1051 → «Недостаточно средств»; иначе → «Ошибка оплаты»; ERROR→IDLE 3000 мс
- [ ] Subtask 13 (patch v1): timeout 15000 → красная кнопка + label; →IDLE 3000 мс
- [ ] retry / другая карта / fallback сохранены
- [ ] targeted + regress зелёные
