# todo — #26 Repeat order invalid token · PaymentMethodsSheet (SPEC 2026-08-07)

**ТЗ:** [`customer_tasks/Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md)  
**Артефакты:** [`repeat_order_invalid_token_payment_sheet/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/)  
**Канон UI (владелец):** скрин **`03_…_2026-08-07.png`** (= визуал `01`) — **если текст ТЗ совпал, а код нет — делаем как на скрине**  
**Стек:** Svelte `app/frontend/` · компонент `PaymentMethodsSheet` (не React `PaymentMethodBottomSheet`)  
**Ограничения ТЗ:** не трогать auth store / refresh; не `legacy/ui`; не новый BottomSheet-менеджер; тексты — через `paymentMethodI18n.js`

---

## Маппинг ТЗ → CoffeeOS

| ТЗ заказчика | Канон CoffeeOS |
|---|---|
| `PaymentMethodBottomSheet` | `PaymentMethodsSheet.svelte` |
| `isTokenInvalid` / auth token | **RebillId карты** · `repeatInvalidTokenStore.js` (sessionStorage после fail `one_click`) — **не** auth JWT |
| Vitest / React path | Rails `test/integration/shop/repeat_invalid_token_payment_test.rb` + `test/javascript/repeat_invalid_token_payment_test.mjs` |
| Peek CTA «Добавить карту» | `CartSheet.svelte` + `shouldShowAddCardCta` |
| Inline pay errors | `inlineError` в sheet + `CheckoutPayButton` FSM |
| i18n | `app/frontend/lib/paymentMethodI18n.js` (не YAML) |

---

## Канон скрина 03 (что должно быть в UI)

| Элемент | Канон (скрин 03) |
|---|---|
| Заголовок | «Способ оплаты» + кнопка X |
| Сохранённая карта | Текст **`Картой *1594`**: слово «Картой» **оранжевое** (`#ff8c42`), маска `*1594` белая; **оранжевая рамка** в selected |
| СБП | Одна строка «СБП», **серый / без оранжевой рамки**, **disabled** (тап → toast `sbpUnavailable()` или ignore) |
| Добавить карту | «Картой» + «**+**» справа (не шеврон `⌄`); оранжевая рамка как на макете |
| CTA в sheet | Крупная **оранжевая** pill «Оплатить» (не синий `#3b82f6`) |
| Peek (фон) | Позиции корзины видны над блоком способов (stacked sheet) — уже baseline |

---

## As-is (код сейчас) vs gap

| # | Тема | As-is | Gap / действие | Приоритет |
|---|---|---|---|---|
| B1 | Peek CTA «Добавить карту» при invalid rebill + repeat + cart | `[x]` работает (`CartSheet` / store) | Не трогать без регрессии | baseline |
| B2 | Open sheet по CTA, title + X, stacked | `[x]` | Не трогать | baseline |
| B3 | Выбор карты → selected + CTA «Оплатить» | `[x]` логика есть | Визуал selected — см. G1 | baseline+G1 |
| B4 | NewCardForm по «Картой +» | `[x]` | Визуал ряда — G3 | baseline+G3 |
| B5 | Inline pay error / persist selection / close | `[x]` unit + MCP v393 (step5 live — unit only) | Soft: live MCP step5 optional | soft |
| **G1** | Лейбл карты | `MIR` chip + `**** 1594` + radio | → **`Картой *XXXX`**, «Картой» orange; убрать/скрыть brand chip+radio если мешают макету | **MUST** |
| **G2** | CTA «Оплатить» в sheet | `CheckoutPayButton` DEFAULT **синий** `#3b82f6` | → **оранжевый** `#ff8c42`, тёмный текст (как скрин) | **MUST** |
| **G3** | Ряд «Картой +» | текст `Картой +` + шеврон `⌄`; border только selected | → «Картой» + **`+`** справа; оранжевая рамка по макету | **MUST** |
| **G4** | СБП | **enabled** (эпик #27 deep link); тесты forbid permanent disable | Скрин/ТЗ #26: **disabled + серый**; toast `sbpUnavailable()` | **MUST** · **конфликт с #27/#34** — см. Decision |
| G5 | i18n `formatCardRowLabel` | `**** 1594` (канон Step10 #27) | Нужна форма `Картой *1594` для sheet (#26 скрин) | MUST вместе с G1 |
| G6 | Тесты | assert `**** 1594`; SBP not permanently disabled | Обновить под канон 03; зеркало Rails+JS | MUST после GREEN |
| Soft | Cold-start `rebill_valid` API | нет | Backlog, без DDL в этом шаге | out of scope |

---

## Decision (нужен апрув владельца в SPEC)

### D1 — СБП vs эпик deep link (#27 / #34)

Скрин 03 + ТЗ #26: СБП **disabled**.  
Код + тесты `sbp_payment_ui_test` / `checkout_acceptance_cbr` / `repeat_invalid_token_payment_test`: СБП **не** permanently disabled.

**Предложение SPEC (как на скрине):** в `PaymentMethodsSheet` СБП снова **disabled** + toast `sbpUnavailable()`; обновить тесты #26/#CBR, которые forbid disable.  
Эпик #27 Zero-Click / deep link — **отдельный follow-up** после апрува заказчика (не смешивать в GREEN #26).

Альтернатива (если владелец скажет иначе): disabled **только** при `isTokenInvalid` — слабее макета (на скрине СБП всегда серый).

→ **По умолчанию в BUILD после go: D1 = disabled всегда в sheet (как скрин 03).** Сменить только явным «нет, оставь СБП».

### D2 — Маска карты `Картой *1594` vs `**** 1594` (#27 Step10)

Скрин 03: `Картой *1594`.  
`paymentMethodI18n.formatMaskedPan`: `**** 1594`.

**Предложение:** для строк sheet — `formatCardRowLabel` → префикс «Картой» + `*XXXX` (одна `*`, не `****`); Step10-тесты маски обновить или сузить к другому хелперу, если ещё нужен `****`.

→ **По умолчанию: как скрин 03.**

### D3 — Оранжевый Pay только в sheet или глобально в `CheckoutPayButton`

**Предложение:** prop/variant `accent="orange"` (или CSS override в `.pm-sheet__pay`) — **не** ломать FSM-синий в других контекстах без нужды. Если `CheckoutPayButton` используется только в sheet — можно сразу оранжевый default.

---

## План BUILD (после апрува SPEC)

### RED

1. Обновить/добавить контракт-тесты под канон 03:
   - `formatCardRowLabel` / i18n → `Картой *1594` (или составной label с data-атрибутами)
   - SBP row: `disabled` / `aria-disabled` + `sbpUnavailable` wired
   - «Картой +»: наличие `+`, отсутствие шеврона `⌄` в new-card row
   - Pay CTA в sheet: оранжевый (`#ff8c42` / data-attr)
2. Коммит `test: … [RED]` — без CHANGELOG/HANDOFF

### GREEN

1. `paymentMethodI18n.js` — лейблы под скрин  
2. `PaymentMethodsSheet.svelte` — разметка/CSS G1–G4  
3. `CheckoutPayButton` / `.pm-sheet__pay` — оранжевый idle  
4. Починить конфликтующие integration-тесты SBP  
5. Регрессия зоны оплаты:  
   `bin/rails test test/integration/shop/repeat_invalid_token_payment_test.rb` + related SBP/checkout + `node --test test/javascript/repeat_invalid_token_payment_test.mjs`  
6. Коммит `feat: … [GREEN]`

### REVIEW

- Sanity: не тронут auth store; CartSheet stacking ок  
- Ops: CHANGELOG / HANDOFF / SESSION_STATE  
- MCP re-verify vs скрин 03 — **только по явной просьбе** (push/deploy)

---

## Чеклист шагов (из ТЗ → статус)

| Шаг | Суть | Статус SPEC |
|---|---|---|
| 1 | Peek CTA «Добавить карту» | baseline `[x]` · регрессия в GREEN |
| 2 | BottomSheet список как скрин 03 | **G1–G4** `[ ]` |
| 3 | Выбор карты → selected + «Оплатить» | baseline + G1/G2 `[ ]` |
| 4 | «Картой +» → NewCardForm | baseline + G3 `[ ]` |
| 5 | Inline ошибки оплаты | baseline `[x]` · live MCP soft |
| 6 | Close / persist selection | baseline `[x]` |

---

## Exit Criteria

1. Тесты #26 (Rails + JS) зелёные под канон скрина 03  
2. Визуал sheet: `Картой *XXXX` / СБП disabled / `Картой +` / оранжевый «Оплатить»  
3. Линтер зоны (Rubocop при Ruby; FE — существующий node test)  
4. Апрув заказчика / MCP — отдельно после deploy

---

## Порядок

1. **Стоп** — апрув SPEC (особенно D1 СБП, D2 маска)  
2. RED → GREEN → регрессия → REVIEW  
3. Push/MCP — только по явной просьбе
