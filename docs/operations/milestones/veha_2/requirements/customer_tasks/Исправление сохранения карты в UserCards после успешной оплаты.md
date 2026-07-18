# Задача: Исправление сохранения карты в UserCards после успешной оплаты (save_card=true)


## Бизнес-контекст
Пользователь при оформлении заказа вводит данные новой карты (макет 1000008924.png), включает тумблер «Использовать карту для будущих заказов». После успешной оплаты карта должна:
1. Сохраниться в таблице `UserCards` (rebill_id, card_id, pan, exp_date, card_type)
2. Отображаться в списке способов оплаты (макет 1000008925.png) при следующем заходе


**Проблема:** После оплаты в 13:14 с включённым тумблером, при повторном заходе в 13:23 карта отсутствует в списке на макете 1000008925.png (не появилась карточка типа «МИР Карта *5953»).


## Глобальные ограничения
- Не менять структуру таблицы `UserCards` (id, user_id, rebill_id, card_id, pan, exp_date, card_type).
- Не менять контракт RSA-шифрования CardData на фронте (PAN;ExpDate;CVV → RSA-2048).
- Не менять стейт-машину кнопки «Оплатить» (состояния 0–7).
- Не менять UI-компоненты формы ввода карты (макет 1000008924.png): поля «Номер карты», «ММ/ГГ», «CMC/CVV», тумблер.
- Не менять UI списка сохранённых карт (макет 1000008925.png): отображение «МИР Карта *5953», «Mastercard *8339» и т.д.
- Не менять эндпоинты Т-Банка `/Init`, `/FinishAuthorize`, `/Charge`.

## Канон UX checkout (истина — только заказчик)

**Приоритет:** скрины в [`artifacts/usercards_save_card/screenshots/`](../../artifacts/usercards_save_card/screenshots/) **выше** B1.13 «CartSheet только на каталоге», B1.7 «Оплатить →» в теле страницы, ops/HANDOFF «resolved» без MCP заказчика.

**На `#/checkout` должно быть (как на скрине заказчика с peek + «Новая карта»):**

1. **CartSheet внизу** — peek с позициями корзины (не `hidden`-чип с каталога).
2. **PaymentMethodsSheet** поверх peek — список карт / «Новая карта» / FSM «Оплатить».
3. **Нет** отдельной кнопки «Оплатить →» и блока «Картой/СБП» в теле `Checkout` — оплата только из шторки заказа (`+сумма` → `shop:checkout-pay`).

**Приёмка:** MCP Fly или скрин заказчика. Grep-тесты «функция есть в файле» **не закрывают** этот блок.

- [ ] **Given:** в корзине есть позиции, пользователь на `#/checkout`, email подтверждён.
- [ ] **When:** смотрим экран оформления.
- [ ] **Then:** внизу виден peek позиций; по «+сумма» открывается PaymentMethodsSheet; в теле страницы нет «Оплатить →».

**Не канон (игнорировать при реализации):** «CartSheet только на каталоге» (B1.13 Q-epic-2) для маршрута checkout.


## Сценарии реализации (Use Cases в Gherkin)


### Шаг 1. Заполнение формы новой карты (макет 1000008924.png)


- [x] **Given:** Пользователь нажал «Новая карта» на экране 1000008925.png, открылась форма 1000008924.png.
- [x] **When:** Пользователь вводит:
  - Номер карты (с маской по 4 цифры, валидация Луна)
  - Срок действия (ММ/ГГ с автослэшем)
  - CMC/CVV (3-4 цифры)
  - Включает тумблер «Использовать карту для будущих заказов» (ON по умолчанию)
- [x] **Then:** Кнопка «Оплатить» активна. В стейте формы установлен флаг `save_card: true`. В DevTools → Network открытый PAN/CVV отсутствуют.

**Отчёт Шаг 1 (Было → Стало):**

| Было (после WIPE) | Стало |
|---|---|
| Нет формы карты, нет Luhn/маски/save_card | `app/frontend/lib/shopNewCardForm.js` + `NewCardForm.svelte` |
| Checkout только OTP → bank redirect | Форма 1000008924: PAN/ММ/ГГ/CVV + тумблер ON (`save_card: true`) |
| Нечего валидировать перед оплатой | `isPayEnabled` = Luhn + exp + CVV; Network snapshot без открытого PAN/CVV |
| — | Тест: `bin/rails test test/integration/shop/shop_new_card_form_step1_test.rb` — 12 runs PASS |


### Шаг 2. Оплата новой карты с сохранением


- [x] **Given:** Форма 1000008924.png заполнена, тумблер ON, стейт кнопки = `Default` (синяя, текст «Оплатить»).
- [x] **When:** Пользователь нажимает «Оплатить». Фронт шифрует CardData (RSA-2048), отправляет на бэкенд: `{ CardData, amount, save_card: true }`.
- [x] **Then:** 
  - Бэкенд вызывает `/Init` → получает PaymentId
  - Вызывает `/FinishAuthorize` с CardData → получает `CONFIRMED`, `RebillId`, `CardId`, маску PAN, тип карты
  - Создаётся запись в `UserCards` с полями: `user_id`, `rebill_id`, `card_id`, `pan` (формат `*5953`), `exp_date` (ММ/ГГ), `card_type` (MIR/VISA/MASTERCARD)

**Отчёт Шаг 2 (Было → Стало):**

| Было (после WIPE / Шаг 1) | Стало |
|---|---|
| `finish_authorize` stub wipe | `TbankAdapter#finish_authorize` → `/FinishAuthorize` + CardData |
| Нет записи карты | `SavedCardStore` → `mobile_payment_methods` (= UserCards): `*5953`, `09/27`, `MIR` |
| Нет nonPCI оркестрации | `NewCardPaymentService` + `POST /shop/api/payments/new_card` |
| Нет RSA на фронте | `tbankCardFormat.js` + `tbankCardEncrypt.js` (jsencrypt) + `GET …/card_config` |
| — | Тест: `shop_new_card_payment_step2_test.rb` + adapter/sync — зона **39 runs PASS** |

**Не сделано в Шаге 2:** Checkout ещё не монтирует форму / не дергает `payments/new_card` (список карт + кнопка «Новая карта» — Шаг 3; Charge — Шаг 4).


### Шаг 3. Отображение сохранённой карты в списке (макет 1000008925.png)


- [x] **Given:** В таблице `UserCards` существует запись для `user_id` с валидным `exp_date`.
- [x] **When:** Пользователь заходит на экран выбора способа оплаты.
- [x] **Then:** Фронт вызывает `GET /api/user/cards`, получает массив карт. UI рендерит список:
  - Для каждой карты: иконка платёжной системы (МИР/Mastercard/Visa) + текст «Карта *XXXX» (где XXXX — последние 4 цифры из `pan`)
  - Пример: «МИР Карта *5953», «Mastercard *8339»
  - Кнопка «Новая карта» внизу списка
  - Кнопка «Оплатить» активна при выборе любой карты

**Отчёт Шаг 3 (Было → Стало):**

| Было | Стало |
|---|---|
| Нет GET списка карт | `GET /shop/api/user/cards` (+ фильтр истёкших) |
| Нет UI 1000008925 | `PaymentMethodsSheet.svelte` + labels «МИР Карта *XXXX» |
| Checkout без листа карт | Checkout грузит `/user/cards`, sheet + «Новая карта» + NewCardForm |
| — | Тесты step3+1+2+CBR: **35 runs PASS** · vite build PASS |

**Не сделано в Шаге 3:** Charge 1 клик (Шаг 4); `payments/new_card` с формы sheet (пока sheet Pay → базовый submit/redirect).


### Шаг 4. Оплата в 1 клик по сохранённой карте


- [x] **Given:** Пользователь выбрал сохранённую карту из списка (например, «МИР Карта *5953»), стейт кнопки = `Default`.
- [x] **When:** Пользователь нажимает «Оплатить».
- [x] **Then:** Фронт отправляет `{ card_id, amount }` на эндпоинт оплаты по токену. Бэкенд достаёт `RebillId` из `UserCards`, вызывает `/Init` → `/Charge`. Форма 1000008924.png не показывается.

**Отчёт Шаг 4 (Было → Стало):**

| Было | Стало |
|---|---|
| `charge` / `charge_recurrent` wipe-stub | `TbankAdapter#charge` → `/Charge` + `charge_recurrent` Init→Charge |
| Sheet Pay → redirect `/orders` | Sheet Pay (saved) → `POST /payments/one_click` `{ card_id }` |
| Нет 1-клик сервиса | `OneClickPaymentService` + `RecurrentOrderCreator` → RebillId → CONFIRMED |
| Форма могла мешать | NewCardForm только при `selectionMode === "new_card"` |
| — | Тесты step1–4 + adapter + CBR: **60 runs PASS** · vite PASS |

**Не сделано в Шаге 4:** 3DS overlay UI; Pay по «Новая карта» через RSA `new_card` (Шаг 5/2 wiring); `save_card: false` (Шаг 6).


### Шаг 5. Добавление второй карты (дублирование сценария)


- [x] **Given:** У пользователя уже есть сохранённые карты (макет 1000008925.png: *5953, *5938, *8339, *1594).
- [x] **When:** Пользователь нажимает «Новая карта», заполняет форму 1000008924.png с `save_card: true`, оплачивает.
- [x] **Then:** Новая карта появляется в списке следующей (после *1594). Список не дублируется, сортировка по дате добавления (новые сверху или снизу — согласно текущей логике).

**Отчёт Шаг 5 (Было → Стало):**

| Было | Стало |
|---|---|
| Sheet «Новая карта» → базовый `/orders` redirect | RSA `encryptCardPayload` → `POST /payments/new_card` + `save_card` |
| Дубль возможен по pan+exp при новом RebillId | `SavedCardStore` upsert по rebill **и** pan+exp |
| Список не обновлялся после new_card | После оплаты `loadSavedCards()`; новые сверху (`last_used_at desc`) |
| — | Тесты step1–5 + CBR: **44 runs PASS** · vite PASS |

**Не сделано в Шаге 5:** 3DS overlay; Шаг 6 `save_card: false`.


### Шаг 6. Оплата без сохранения (save_card=false)


- [x] **Given:** Пользователь заполнил форму 1000008924.png, выключил тумблер (OFF).
- [x] **When:** Оплата прошла успешно (`CONFIRMED`).
- [x] **Then:** Запись в `UserCards` НЕ создаётся. При следующем заходе на экран 1000008925.png новая карта не появилась в списке.

**Отчёт Шаг 6 (Было → Стало):**

| Было | Стало |
|---|---|
| Поведение `save_card=false` не покрыто тестом | Тест: CONFIRMED + RebillId от банка → UserCards **пусто** · GET без `*9999` |
| Init мог бы идти с Recurrent=Y всегда | `recurrent: false` при OFF; Checkout шлёт `save_card` из тумблера |
| — | step1–6 + CBR: **47 runs PASS** · vite PASS |

**Не сделано в Шаге 6 (вне Gherkin этого шага):** 3DS overlay UI; extreme webhook fallback отдельным шагом.


## Экстремальные сценарии (Error & Edge States)

| Сценарий | Статус | Артефакт |
|---|---|---|
| Ошибка БД при записи UserCards + webhook upsert | **[x]** | `TbankCallbackJob` + soft-fail в `NewCardPaymentService` · E1/E1b |
| Нет RebillId → нет строки + тумблер OFF | **[x]** | BE E2 · FE `setSaveCard(..., false)` |
| Дубликат PAN+exp | **[x]** | Step 5 / SavedCardStore |
| Истёкший срок | **[x]** | Step 3 GET filter |
| 3DS_CHECKING → карта не пишется | **[x]** | E5 backend + **UI Client Error / overlay FSM 0–7** |
| Net Error «Нет сети: повторить» | **[x]** | FSM State 7 · `shopPayFsm` |
| Пустой список | **[x]** | E7 sheet labels |

Тесты: `shop_user_cards_extremes_test.rb` — **7 runs PASS** · `shop_pay_fsm_3ds_test.rb` PASS.

- **Ошибка БД при записи в UserCards (500):** Платёж прошёл, но запись карты упала. Фронт показывает стейт кнопки `Success` → редирект. При следующем заходе на 1000008925.png карта не появилась. Webhook от Т-Банка выполняет upsert.
- **Т-Банк не вернул RebillId:** Бэкенд не создаёт запись в `UserCards`. Фронт не показывает карту на 1000008925.png. Тумблер на форме 1000008924.png сбрасывается в OFF.
- **Дубликат карты (тот же PAN + exp_date):** Upsert по `(user_id, pan_last4, exp_date)`. На 1000008925.png не появляется дубль «МИР Карта *5953».
- **Истёкший срок карты:** При `GET /api/user/cards` бэкенд фильтрует карты с `exp_date < текущий месяц`. На 1000008925.png карта не отображается.
- **3D-Secure прерван:** Стейт кнопки = `3D-Secure` → пользователь закрыл iframe. Кнопка → `Client Error` («Отказ: смените карту»). Карта не сохраняется. **`[x]`** overlay + FSM.
- **Сеть пропала (State 1 → Net Error):** Запрос не дошёл. Кнопка = `Net Error` («Нет сети: повторить»). Форма 1000008924.png остаётся заполненной, данные не потеряны.
- **Пустой список карт (первый вход):** На 1000008925.png отображаются только: «СБП», «Новая карта», кнопка «Оплатить» (disabled или активна только для СБП).


## Критерии авто-выхода (Exit Criteria)


1. Код проходит unit/интеграционные тесты под эти сценарии.
2. Проверка типов TypeScript (tsc) и линтер проходят без ошибок сборки.
3. **Тест-кейс «Сохранение»:** После оплаты с `save_card: true` — `GET /api/user/cards` возвращает карту с `pan="*5953"`, `card_type="MIR"`, `exp_date="09/27"`.
4. **Тест-кейс «Отображение»:** На экране 1000008925.png появилась карточка «МИР Карта *5953» с корректной иконкой МИР.
5. **Тест-кейс «1 клик»:** Оплата по выбранной карте *5953 проходит через `/Charge` без формы 1000008924.png.
6. **Тест-кейс «Без сохранения»:** При `save_card: false` запись в `UserCards` не создаётся, на 1000008925.png карта не появилась.
7. **Тест-кейс «Webhook»:** Webhook от Т-Банка выполняет upsert в `UserCards` при повторной доставке (idempotency по `PaymentId`).
8. В DevTools → Network ни один запрос не содержит открытый PAN или CVV.
9. Визуальное соответствие макетам:
   - 1000008924.png: поля «Номер карты», «ММ/ГГ», «CMC/CVV», тумблер ON
   - 1000008925.png: список карт с иконками (МИР, Mastercard), текст «Карта *XXXX», кнопка «Новая карта»

## Скрины к задаче (артефакты)

Канон: [`artifacts/usercards_save_card/screenshots/`](../../artifacts/usercards_save_card/screenshots/)

| Скрин | Файл |
|-------|------|
| макет 1000008925.png | [`1000008925_payment_methods_list.png`](../../artifacts/usercards_save_card/screenshots/1000008925_payment_methods_list.png) |
| макет 1000008924.png | [`1000008924_new_card_form.png`](../../artifacts/usercards_save_card/screenshots/1000008924_new_card_form.png) |
| 13:19 время оплаты — оплата прошла успешно | [`bug_13-19_payment_success_save_card_on.png`](../../artifacts/usercards_save_card/screenshots/bug_13-19_payment_success_save_card_on.png) |
| 13:23 — повторная покупка — карта не прикреплена | [`bug_13-23_repeat_purchase_card_missing.png`](../../artifacts/usercards_save_card/screenshots/bug_13-23_repeat_purchase_card_missing.png) |

## Фаза 0 — диагностика Fly (2026-07-16, read-only)

**Артефакт:** [`usercards_fly_diagnose_2026-07-16.json`](../../artifacts/usercards_save_card/usercards_fly_diagnose_2026-07-16.json) · скрипт `bin/usercards_fly_diagnose.rb`

| Проверка | Результат | Вывод |
|----------|-----------|-------|
| Release v361, bundle | `application-D1E05YN_.js`, prog24, без inline pay | UX-код на Fly актуален |
| `mobile_payment_methods` (card) | 14 rows | Глобально save работал (dev smoke) |
| `aramfifa100@gmail.com` cards | **0** | **bug_13-23 подтверждён per-customer** |
| Payment 2026-07-15 save_card=true | succeeded, row нет | H3b: persist hook не создал UserCards |
| Worker | **stopped** | async callback риск (H2) |
| SHOP_SIMULATE_PAYMENT | 0 | simulate не блокирует |

**Exit criteria §3–4 на Fly:** **не пройдены** для email заказчика — ждать deploy Фазы 1.

## Фаза 1 — fix persist (2026-07-16)

| Изменение | Файл | Зачем |
|-----------|------|-------|
| Webhook `perform_now` | `callbacks/tbank_controller.rb` | RebillId → SavedCardStore без worker |
| `SOLID_QUEUE_IN_PUMA` | `fly.toml` | очередь на web если worker stopped |
| `recurrent: save_card` | `order_creator.rb` | legacy redirect с сохранением карты |
| E2E | `shop_usercards_phase1_persist_test.rb` | 3 сценария: webhook, replay, finalize |

**После deploy:** повторная оплата aramfifa или replay webhook → `GET /user/cards` с `*5953`.

## Фаза 2 — stacked UX checkout (2026-07-16)

| Шаг | Что | Статус |
|-----|-----|--------|
| 2.1 | Ops: снять ложные `[x]` HANDOFF/ISSUES | `[x]` |
| 2.2 | `openCheckoutPayStack` — peek strip + без backdrop | `[x]` |
| 2.3 | `PaymentMethodsSheet stacked` — expanded снизу | `[x]` |
| 2.4 | Тест `shop_checkout_cart_sheet_ux_test` | `[x]` |
| 2.5 | MCP Fly vs 1000008924/8925 | `[ ]` NOT_RUN |
| 2.6 | Апрув заказчика | `[ ]` |

**Приёмка:** peek `shop-cart-peek-list` виден **одновременно** с `payment-methods-sheet` (`data-payment-sheet-stacked=true`), без `payment-methods-backdrop`.

## Фаза 3 — RebillId / вторая карта (2026-07-18)

| Шаг | Что | Статус |
|-----|-----|--------|
| 3.1 | Runbook [`USERCARDS_SAVE_CARD_FLOW.md`](../runbooks/USERCARDS_SAVE_CARD_FLOW.md) | `[x]` |
| 3.2 | Root cause платежа 8866531465 (Fly) | `[x]` — [`usercards_fly_payment_root_cause_2026-07-18.json`](../artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json) |
| 3.3 | Fix retry GetState + тесты | `[x]` — `sync_for_rebill!` 5× pause 1s · log `[UserCards] missing RebillId` |
| 3.4 | Fly: реальная 2-я карта в списке | `[ ]` |
| 3.5 | Апрув заказчика | `[ ]` |

Runbook: **оплата ≠ привязка**; без RebillId карта в 8925 не появится.

## Приёмка Fly v362 (2026-07-16)

| Проверка | Результат | Артефакт |
|----------|-----------|----------|
| Replay webhook 0₽ | PASS — MIR *5953 | `usercards_fly_phase1_verify_2026-07-16.json` |
| MCP PaymentMethodsSheet | PASS — «МИР Карта *5953» | `usercards_phase1_mcp_2026-07-16.json` |
| Новая оплата 5₽ | NOT_RUN | экономия |

**Exit criteria §3–4:** **не пройдены** для E2E 2-й карты (*8782). Replay/MCP *5953 — только smoke Фазы 1, не закрывает bug_13-23 полностью. Апрув заказчика **[ ]**

**Root cause 3.2 (8866531465):** FA 09:56 без RebillId → наш gap (нет retry GetState); RebillId *8782 от банка — 2026-07-17. См. [`usercards_fly_payment_root_cause_2026-07-18.json`](../../artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json).

