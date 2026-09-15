# todo — #87 Quick Repeat status model composition

| Поле | Значение |
|------|----------|
| **ID** | CBR **#87** |
| **Тип** | SBR · доп. задача Quick Repeat → status |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` · `@coffeeos-cart-sheet` |
| **ТЗ** | [`TASK-87-Quick-Repeat-status-model-composition.md`](../milestones/veha_2/requirements/customer_tasks/TASK-87-Quick-Repeat-status-model-composition.md) |
| **Google** | https://docs.google.com/document/d/1sdkJYZzLgVKiUTWfZuKDkL8kSuBPRNFSRiEFDQsxGbo/edit?usp=drivesdk |
| **Артефакты** | [`quick_repeat_status_model_composition/`](../milestones/veha_2/artifacts/quick_repeat_status_model_composition/) |
| **Unlazy** | [`GATES.md`](GATES.md) — G1–G3 baseline met · G4 Fly pending |
| **OUT** | стандартный checkout composition без отдельного Gherkin · dismiss (#83) · receipt restore API (#84) без нужды · T-Bank widget контракт |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec` — канон в этом todo
- [x] PHASE 2 RED — падающие тесты: post-pay без cart UI · состав из Order · не из cart
- [x] PHASE 2 GREEN — `clearCartAfterSuccessfulPay` + wire в `widgetRepeatPayFlow` · зона PASS
- [ ] PHASE 3 `/review` — bugbot+security · Entire · push/CI · Fly MCP G4

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/lib/createRepeatInlineOrder.js` | one-click создаёт Order через cart; после оплаты leftover cart → 7.1 |
| `app/frontend/lib/widgetRepeatPayFlow.js` | post-success card/widget: очистить cart + синхрон status |
| `app/frontend/lib/cartSheetStore.js` | clear/refresh cart после успешной оплаты (не показывать «купленную» корзину) |
| `app/frontend/components/CartSheet.svelte` | host: status + cart; при active order не рендерить интерактив cart (Удалить/±/+N₽) |
| `app/frontend/components/OrderStatusSheet.svelte` | status model: заказ + состав (read-only), не cart |
| `app/frontend/lib/orderStatusSheet.js` | load/poll `/orders/active` · `has_active_order` после one-click |

**Blast-radius (+соседи, только если RED покажет дыру):**

| Path | Почему |
|------|--------|
| `app/frontend/lib/frequentRepeatStore.js` | `hasActiveOrder` скрывает Repeat; sync после pay |
| `app/frontend/components/ActiveOrdersAccordion.svelte` | receipt/состав (#84) — только если состав не виден без правок |
| `app/frontend/components/RepeatSection.svelte` | точка вызова one-click → pay flow |

## Не ломать

1. Card / Rebill / Charge / widget Init контракт (кроме post-success UI sync).
2. Стандартный checkout: товар → корзина → оплата — composition/peek без скрытого изменения.
3. OrderStatusSheet / active orders / dismiss (#83) / receipt CTA (#84) — не регрессить.
4. Peek cart на карточке товара (#44) и empty/repeat slots без active order.

## Проверка

```bash
node --test test/javascript/create_repeat_inline_order_test.mjs test/javascript/order_status_sheet_test.mjs
ruby bin/rails test test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/active_order_cart_peek_stack_test.rb test/integration/shop/api/active_orders_test.rb test/integration/shop/api/active_orders_receipt_test.rb
```

**После GREEN / Review:** Fly MCP Point A (G4) — скрин: status без «Удалить»/±/`+N₽`; состав = Order. Артефакт в `artifacts/quick_repeat_status_model_composition/`.

## DoD (из ТЗ + 7.1)

- [x] Quick Repeat one-click после оплаты → Order в status model
- [x] Состав = позиции Order (+ кастомизации), не текущая корзина
- [x] 7.1: после card autopay нет интерактивного блока корзины (Удалить / ± / Итого+CTA)
- [x] Защитный контракт стандартного checkout не сломан
- [ ] G1–G3 `--reverify` met · G4 Fly или skip+reason
- [ ] До Review `COMPONENT_MAP.md` не трогать; после Review — точечно
