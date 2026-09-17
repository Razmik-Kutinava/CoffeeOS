# todo — #93 TASK_91: post-pay auto return → catalog + status

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** (Google: TASK_91) |
| **Тип** | SBR · EXT #71 post-pay → авто `#/` + status model |
| **Статус** | **GREEN** 2026-09-17 · ждёт `/regress` → `/review` |
| **RED** | `350f6b95` |
| **GREEN** | _(fill after commit)_ |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-91-Автоматический-возврат-на-каталог-после-post-pay-email.md`](../milestones/veha_2/requirements/customer_tasks/TASK-91-Автоматический-возврат-на-каталог-после-post-pay-email.md) |
| **Google** | https://docs.google.com/document/d/1nlWXyWV0UcV5X33i0owZixXRJl5d-nF_HwHdjjBVd2o/edit |
| **Артефакты** | [`post_pay_auto_return_catalog_status/`](../milestones/veha_2/artifacts/post_pay_auto_return_catalog_status/) · screenshots `01`–`03` |
| **GATES** | [`GATES.md`](GATES.md) — G1–G3 baseline met · G4 Fly pending |
| **OUT** | Checkout `completePaySuccess` · SBP #79/#86 · OrderStatusSheet internals · Quick Repeat #87 · `isCartSheetRoute` + `/payment-result` · settleSuccess → `/order/:id` |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `350f6b95`
- [x] PHASE 2 GREEN
- [ ] PHASE 3 `/review`

## Next

`/regress` — зона Проверка; затем `/review`.

## DoD

1. Success `#/payment-result?status=ok` + **email блок** → после submit или Skip уже есть `push("/")` — сохранить.
2. Success + **без** email-блока (`askReceiptEmail === false`, чек email в LS — типичный повтор / карточка товара) → **авто** `push("/")` после готовности success screen; без обязательного клика «В каталог».
3. Пока email-блок виден — **нет** auto-redirect при mount (защита #71 / `email_collection_test` ~73–80).
4. CTA `payment-result-continue` «В каталог» остаётся совместимым с #35 (`onclick={handleEmailSkip}`).
5. На `#/` — существующая статусная модель без правок её логики.

## Факт кода (SPEC)

| Вопрос Spec | Ответ |
|-------------|--------|
| Кто завершает email submit | `handleEmailSubmit` → `submitOrderEmail` → `saveReceiptEmail` → `push("/")` |
| Кто Skip | `handleEmailSkip` → delay 200ms → `push("/")`; Continue = тот же handler |
| Когда email-flow «завершён» | submit ok / Skip / **или** `shouldAskReceiptEmail(savedReceipt) === false` (блок не показывают) |
| Nav API | `push` из `svelte-spa-router` → `push("/")` |
| Runner #71 | `node --test test/javascript/email_collection_test.mjs` |
| Runner #35 | `ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb` |

**Gap:** ветка `{:else}` (~198–208) только кнопка «В каталог» — автоперехода нет → скрин заказчика `01_stuck_…`.

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/routes/PaymentResult.svelte` | Авто `push("/")` когда success готов и `!askReceiptEmail`; не трогать mount→email path |
| `test/javascript/email_collection_test.mjs` | RED: auto-nav при known receipt; regression: нет immediate redirect при ask email |
| `test/integration/shop/order_status_acceptance_cbr_test.rb` | `#35` Continue / `push("/")` остаётся |

### Blast-radius (не менять, только не сломать)

| Path | Почему сосед |
|------|----------------|
| `app/frontend/lib/emailCollection.js` | `shouldAskReceiptEmail` — контракт gate email-блока |
| `app/frontend/components/OrderSuccessEmailBlock.svelte` | UI submit/skip; handlers снаружи |
| `app/frontend/lib/cartSheetStore.js` | `isCartSheetRoute` — не добавлять `/payment-result` |

## Не ломать

1. Card / Rebill / one-click / SBP оплата и `completePaySuccess` → `#/payment-result?status=ok&order_id=…`.
2. #71 email-блок при первом success: нет auto-redirect до submit/Skip.
3. #35 Continue «В каталог» / acceptance `order_status_acceptance_cbr_test`.
4. SBP waiting/recover #79/#86 · Quick Repeat #87 · статусная модель на `#/` без mount на payment-result.

## Проверка

```bash
node --test test/javascript/email_collection_test.mjs
ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
```
