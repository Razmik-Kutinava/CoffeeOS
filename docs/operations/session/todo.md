# todo — Repeat order invalid token · PaymentMethod BottomSheet

> **ТЗ:** [`customer_tasks/Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md)  
> **Артефакты:** [`artifacts/repeat_order_invalid_token_payment_sheet/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/)

## Текущая фаза

**PHASE 1: SPEC** — `[x]` · код не трогали · ждём намерения на RED

---

## As-is (2026-07-27)

| Область | Сейчас | Файлы |
|---------|--------|-------|
| Повтор «в 1 клик» | `repeatPayOneClickItem` → корзина → `#/checkout` → `REPEAT_AUTOPAY_KEY` → авто `openPaymentSheet()` | `frequentRepeatStore.js`, `RepeatSection.svelte`, `Checkout.svelte` |
| Peek CTA | Всегда `+сумма` → `/checkout` или `shop:checkout-pay` на checkout | `CartSheet.svelte` |
| PaymentMethodsSheet | Карты + disabled СБП («Будет позже») + «Новая карта» + FSM «Оплатить» | `PaymentMethodsSheet.svelte`, `Checkout.svelte` |
| Ошибки оплаты | FSM 5–7 на кнопке; `err` на **странице** checkout, не inline в sheet | `shopPayFsm.js`, `Checkout.svelte` |
| Ошибки загрузки карт | `loadSavedCards` catch → пустой список, **без** inline retry | `Checkout.svelte` |
| i18n | Нет общего i18n; подписи в `paymentMethodLabels.js` + хардкод в sheet | `paymentMethodLabels.js` |
| Invalid rebill | Нет флага `isTokenInvalid`; API `GET user/cards` не отдаёт валидность RebillId | `SavedCardJson`, `user_cards_controller.rb` |
| Тесты (ТЗ) | Путь `src/features/checkout/...` **не существует** — стек **Svelte** + `test/javascript/*.mjs` + mirror Ruby | `phone_otp_ui_test.mjs` |

**Скрин заказчика:** peek корзины + stacked `PaymentMethodsSheet`, подписи «Картой *1594», «Картой +», CTA «Оплатить» — [`01_payment_method_bottom_sheet_invalid_token_2026-07-27.png`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/screenshots/01_payment_method_bottom_sheet_invalid_token_2026-07-27.png)

---

## Gap → решения SPEC

| # | Gap | Решение (без нарушения ограничений ТЗ) |
|---|-----|----------------------------------------|
| G1 | Нет `isTokenInvalid` | Новый **локальный** модуль `repeatInvalidTokenStore.js` (не auth store): `sessionStorage` ключ `shop_invalid_rebill_{cardId}` + writable `isTokenInvalid`. Выставлять после `one_click` 422 + CLIENT_ERROR / rebill-коды; сбрасывать после успешной оплаты или новой карты. |
| G2 | CTA peek «Добавить карту» | `CartSheet.svelte`: если `isTokenInvalid && repeatContext` (корзина не пуста + frequent или флаг repeat) — кнопка `data-testid="shop-cart-add-card"` вместо `shop-cart-sheet-checkout`; текст из i18n. |
| G3 | Открытие sheet с каталога | Клик «Добавить карту»: `push("/checkout")` + событие открытия (расширить `REPEAT_AUTOPAY_KEY` или новый `shop_open_payment_sheet`). Ошибка preload (400/500 на `user/cards`) → **тост** (`repeatFeedback` или cart toast), sheet **не** открывать. |
| G4 | Inline ошибки в sheet | Props `PaymentMethodsSheet`: `inlineError`, `loadError`, `onRetryLoad`. Баннер над `CheckoutPayButton`; sheet **не** закрывать при 400/500 pay. |
| G5 | Подписи «Картой *XXXX» / «Картой +» | Новый `paymentMethodI18n.js` (канон i18n для способов оплаты); `formatCardRowLabel`, `labelSbp`, `labelAddCard`, `ctaAddCard`, `ctaPay`, `sbpUnavailable`. Убрать хардкод из sheet. |
| G6 | СБП disabled + тост | Оставить `disabled`; по тапу (если разрешим) — тост «СБП временно недоступно» (i18n). a11y: `aria-disabled="true"`. |
| G7 | Сохранение выбора после close | `repeatInvalidTokenStore`: `selectedCardId`, `selectionMode` — persist в sessionStorage; restore при reopen. |
| G8 | Cold start без прошлого fail | **MVP:** флаг только после неудачного `one_click`. **Опционально (отдельный подшаг + migration gate):** `rebill_valid` в `SavedCardJson` + пометка в БД при fail Charge — **не в первом RED**, если не блокирует приёмку. |

**Запрещено (ТЗ):** трогать `silentRefreshSession` / refresh auth; `legacy/ui`; новый BottomSheet-комponent; менеджер `checkoutPayOpen` / `openCheckoutPayStack` — только вызовы.

---

## Файлы реализации (GREEN)

| Файл | Действие |
|------|----------|
| `app/frontend/lib/paymentMethodI18n.js` | **create** — тексты способов оплаты |
| `app/frontend/lib/repeatInvalidTokenStore.js` | **create** — `isTokenInvalid`, persist selection |
| `app/frontend/lib/paymentMethodLabels.js` | **extend** — использовать i18n для list labels |
| `app/frontend/components/PaymentMethodsSheet.svelte` | inline error/retry, i18n, SBP toast |
| `app/frontend/components/CartSheet.svelte` | CTA «Добавить карту» |
| `app/frontend/routes/Checkout.svelte` | wire store, sheet errors, invalid detection on pay fail |
| `app/frontend/lib/frequentRepeatStore.js` | hook после failed repeat path (минимально) |
| `test/javascript/repeat_invalid_token_payment_test.mjs` | unit: store + i18n + CTA mapping |
| `test/integration/shop/repeat_invalid_token_payment_test.rb` | mirror/grep + API edge (если backend) |

**RLS:** только чтение `user/cards` по tenant session — без изменений схемы в MVP.

**Регрессия (GREEN):** `bin/rails test test/integration/shop/` · `node --test test/javascript/repeat_invalid_token_payment_test.mjs`

---

## Чеклист шагов (из ТЗ)

### Шаг 1 — CTA «Добавить карту» в peek при invalid token
- [ ] Given: главный экран (`/` или `#/checkout`), repeat context, `isTokenInvalid`, mode peek
- [ ] Then: «Оплатить» / `+сумма` скрыты → CTA «Добавить карту»
- [ ] Click → open PaymentMethodsSheet (через checkout stack)
- [ ] Pre-open API 400/500 → тост, sheet не открывается

### Шаг 2 — Рендер BottomSheet «Способ оплаты»
- [ ] Header + close (X)
- [ ] Список: «Картой *1594» selected, СБП disabled, «Картой +»
- [ ] Load error 400/500 → inline stub + «Повторить»

### Шаг 3 — Выбор существующей карты
- [ ] Tap card → selected (orange border)
- [ ] CTA sheet → «Оплатить» active
- [ ] СБП tap ignored

### Шаг 4 — «+ Картой» / новая карта
- [ ] NewCardForm inline; success → refresh list, «Оплатить» active
- [ ] Add error 400/500 → inline в форме, sheet open, данные сохранены

### Шаг 5 — Ошибки при оплате inline
- [ ] Pay 400/500 → sheet open, banner с текстом, selection сохранён, retry enabled

### Шаг 6 — Закрытие sheet
- [ ] X / swipe down → peek; CTA «Добавить карту» если token still invalid; selection persisted

---

## Тесты (RED → GREEN)

| Кейс | Файл |
|------|------|
| CTA «Оплатить» ↔ «Добавить карту» по `isTokenInvalid` | `repeat_invalid_token_payment_test.mjs` |
| SBP disabled a11y | idem + mirror `.rb` |
| Loading «Оплатить» | idem (FSM CONNECTING/PROCESSING) |
| Inline 400/500 без close sheet | idem + `PaymentMethodsSheet.svelte` |
| Persist selection after close/open | store unit test |
| HTTP map: pre-open → toast; in-sheet → inline | store + Checkout wiring |

---

## Риски

| Риск | Митигация |
|------|-----------|
| «Главный экран» = каталог vs checkout | Покрыть оба маршрута с CartSheet peek; primary UX по скрину — checkout stacked |
| Нет backend `rebill_valid` на cold start | MVP: флаг после fail; документировать в HANDOFF |
| `Checkout.svelte` >200 строк при правках | Вынос логики invalid token в `repeatInvalidTokenStore.js` |
| i18n vs существующие русские строки | Только payment-method namespace; не рефакторить весь PWA |

---

## Exit Criteria (из ТЗ)

- [ ] Все новые тесты зелёные
- [ ] Линтер / tsc (если есть) без ошибок — для JS: `node --test` + mirror Ruby PASS
