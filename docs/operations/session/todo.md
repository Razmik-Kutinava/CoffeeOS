# todo — #26 QA reopen: inline надпись при отказе банка (шаг 5)

| Поле | Значение |
|------|----------|
| **CBR** | #26 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) · UX-тексты [Понятные сообщения…](../milestones/veha_2/requirements/customer_tasks/Понятные%20сообщения%20пользователю%20при%20ошибке%20оплаты.md) |
| **Тип** | Fix / hot-path оплата · PaymentMethodsSheet |
| **Цель** | При отказе банка / 400/500 на «Оплатить» — **inline-надпись** в шторке (что произошло / попробуйте другую карту), sheet не закрывать, выбор карты сохранить, CTA разблокировать |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | после GREEN / REVIEW — MCP (не Local-only) |
| **Ветка** | `develop` |
| **Артефакты QA** | [`…/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/) |
| **Запрет** | новый BottomSheet; трогать auth store / refresh; legacy/ui; gem’ы оплаты; параллельная фича рядом с #26 |

## SBR

- [x] **SPEC** — пути + Не ломать + Проверка + решения
- [ ] **RED** — failing-тесты: `resolveCheckoutSheetInlineError` ≠ null на CLIENT/NET/BANK; выбор карты сохраняется
- [ ] **GREEN** — wire inline + согласовать G7 auto-open с шагом 5
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push

## Баг заказчика → решение SPEC

| # | QA | Решение |
|---|-----|---------|
| 1 | Отказ карты есть, **нет** пояснения («попробуйте другую карту» / что делать) | `resolveCheckoutSheetInlineError` сейчас **всегда `null`** (copy только на CTA). Вернуть `payFsmLabel(fsmState)` / `INLINE_*` для `CLIENT_ERROR` / `NET_ERROR` / `BANK_ERROR` → слот `payment-method-inline-error` в `PaymentMethodsSheet`. Сырой `e.message` / ErrorCode **запрещён**. |
| 2 | После отказа UI снова «Оплатить» без текста | `$effect` G7 (`shouldAutoOpenNewCardOnClientError` → `onSelectNewCard()`) сбрасывает `payFsmState=DEFAULT` и `sheetInlineError=null`. **Шаг 5:** выбранный способ **сохраняется** → **не** авто-сбрасывать FSM/selection; CTA при `CLIENT_ERROR` по клику → `open_new_card` (`resolvePayFsmCtaAction`). Auto-open `$effect` убрать или не вызывать `onSelectNewCard` при pay-decline. |
| 3 | Связка с «Понятные сообщения» | Не форкать тексты: reuse `PAY_FSM_LABELS` / `INLINE_CARD_ERROR_LABEL` / `INLINE_NETWORK_ERROR_LABEL` из `shopPayFsm` + `shopInlinePayFsm`. |

## Файлы (ожидаемо)

1. `app/frontend/lib/shopPayFsm.js` — `resolveCheckoutSheetInlineError` → friendly label; согласовать `shouldAutoOpenNewCardOnClientError` со шагом 5
2. `app/frontend/routes/Checkout.svelte` — catch уже зовёт resolver; убрать/ослабить `$effect` G7, чтобы не стирать inline + selection
3. `app/frontend/components/PaymentMethodsSheet.svelte` — слот `inlineError` уже есть (verify wiring)
4. `app/frontend/components/CheckoutPayButton.svelte` — CTA `CLIENT_ERROR` → `onChangeCard` / `open_new_card` (не silent retry)
5. `test/javascript/payment_error_user_messages_test.mjs` — RED: flip «null for NET/CLIENT/BANK» → ожидать card/network copy
6. `test/javascript/repeat_invalid_token_payment_test.mjs` — RED: шаг 5 inline + selection preserved
7. `test/integration/shop/repeat_invalid_token_payment_test.rb` — зеркало: grep/wiring step5 inline

### Blast-radius (только читать / не ломать без нужды)

8. `app/frontend/lib/shopInlinePayFsm.js` — source of truth текстов (reuse)
9. `app/frontend/components/CartSheet.svelte` — peek CTA / pay-stack open
10. `app/frontend/components/NewCardForm.svelte` — шаг 4 inline внутри sheet

## Не ломать

- One-Click / `POST /shop/api/payments/one_click` + webhook idempotency (Tbank)
- «Повторить» / invalid token → открытие `PaymentMethodsSheet` (шаги 1–4, 6)
- Peek/hidden/expanded CartSheet + checkout pay-stack высота
- G7: клик CTA при отказе карты всё ещё ведёт к форме новой карты (без silent retry той же карты)

## Проверка

- `node --test test/javascript/payment_error_user_messages_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs`
- `bin/rails test test/integration/shop/repeat_invalid_token_payment_test.rb`
