# todo — TASK_94: Повтор покупки из истории ЛК с one-click

| Поле | Значение |
|------|----------|
| **ID** | **TASK_94** / #94 |
| **Тип** | SBR · доп.задача · hot-path shop pay / ЛК |
| **Статус** | **REVIEW · CI green** · deploy апрув |
| **Ветка** | `develop` |
| **ТЗ** | [`TASK-94-Повтор-покупки-из-истории-ЛК-с-one-click-оплатой.md`](../milestones/veha_2/requirements/customer_tasks/TASK-94-Повтор-покупки-из-истории-ЛК-с-one-click-оплатой.md) |
| **GATES** | [`session/GATES.md`](GATES.md) · G1–G4 **met** (reverify) · G5 Fly unmet |
| **Google Doc** | https://docs.google.com/document/d/19QWNuRirU9jGkzFMY7sXXQV8xFTf2oEq_u3Yf0fo-6w/edit |

## SBR

- [x] PHASE 0 /start (intake)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED — `lk_history_repeat_one_click` tests [TDD]
- [x] PHASE 2 GREEN — Profile/OrderReceipt + adapter → existing pay flow
- [x] `/regress` (Проверка) · Local PASS 2026-09-19
- [x] PHASE 3 `/review` — bugbot + security · Entire · push · Fly MCP G5 после deploy

## Файлы (ожидаемо)

1. `app/frontend/routes/Profile.svelte` — `shop-lk-repeat-btn`: не только `openReceipt`, старт repeat выбранного заказа
2. `app/frontend/routes/OrderReceipt.svelte` — заменить stub `onRepeatStub` на реальный repeat + pay orchestration
3. `app/frontend/lib/historyRepeatAdapter.js` *(новый)* — исторический Order → item(s) / вызов существующего `createRepeatInlineOrder` + `runRepeatWidgetPayFlow`
4. `app/frontend/lib/createRepeatInlineOrder.js` — только если адаптеру нужен multi-item / без ломки QR single-card контракта *(не трогали — multi-item в adapter)*
5. `app/controllers/shop/api/orders_controller.rb` — `product_id` в `order_json` items
6. `test/javascript/lk_history_repeat_one_click_test.mjs` *(новый)* — G1
7. `test/integration/shop/lk_history_repeat_one_click_test.rb` *(новый)* — G2

### Blast-radius (соседи, не менять ради ЛК)

- `app/frontend/lib/widgetRepeatPayFlow.js` — **reuse** as-is (Патч 1 inline уже в кнопке)
- `app/frontend/lib/repeatInlinePayUiStore.js` — подключить UI/FSM, не дублировать payment
- `app/frontend/components/RepeatSection.svelte` — эталон оркестрации; QR UI не трогать

## Не ломать

1. Стандартный checkout / `Checkout.svelte` / payment API (`widget_init`, status)
2. Quick Repeat `hasActiveOrder` gate + `RepeatSection` one-click
3. `cartSheetStore.clearCartAfterSuccessfulPay` (#87)
4. `OrderStatusSheet` / `/orders/active` критерии и контракт

## Проверка

```bash
node --test test/javascript/lk_history_repeat_one_click_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs
bundle exec rails test test/integration/shop/lk_history_repeat_one_click_test.rb test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/pwa_personal_account_lk_test.rb
```

## DoD

- [ ] «Повторить» в `#/profile` / receipt → новый Order из выбранного history
- [ ] Существующий Quick Repeat / widget one-click (+ inline статусы кнопки)
- [ ] Исходный historical Order не изменён; composition не из чужой корзины
- [ ] Checkout regression green
- [ ] G1–G4 met · G5 Fly после deploy
- [ ] `COMPONENT_MAP.md` — только после Review (если зона карты)
