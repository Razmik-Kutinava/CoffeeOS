# todo — T-Kassa Widget One-Click + Fallback (#33)

**ТЗ:** [`customer_tasks/Интеграция виджета быстрой оплаты Т-Кассы и One-Click сценария в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20виджета%20быстрой%20оплаты%20Т-Кассы%20и%20One-Click%20сценария%20в%20PWA.md)  
**Артефакты:** `artifacts/tbank_widget_oneclick_fallback/`  
**Фаза:** PHASE 1 SPEC · ждём RED

---

## SPEC (канон CoffeeOS)

### Бизнес-цель
Inline «оплатить в клик» на карточке повтора с fallback при отказе карты: инлайн-плашка «статусы от банка» → кнопки «СБП» / «карта +» → expanded сохранённые карты / форма новой — всё без ухода со страницы.

### Глобальные ограничения (из ТЗ)
- Сумма заказа **только** из БД по orderId, не из клиентского payload.
- `orderId` и контекст корзины **не** инвалидировать при fallback.
- `"connection_type": "Widget"` обязателен в `DATA` метода `Init` Т-Кассы.
- `TerminalKey` / секреты — только ENV backend, не FE.

### Что уже есть (не дублировать)
- `Payments::TbankInlineInit` — Init с PayType "O" / Charge по RebillId
- `Payments::TbankAdapter` — Init, Charge, GetState, Confirm, Token SHA-256
- `Shop::OneClickPaymentService` — one-click оплата через RebillId
- `Shop::NewCardPaymentService` — оплата новой картой
- `RepeatSection.svelte` — карточки «повторить» + кнопка «оплатить в 1 клик»
- `PaymentMethodsSheet.svelte` — bottom sheet выбора метода (saved cards, new card, SBP)
- `frequentRepeatStore.js` → `repeatPayOneClickItem()` — текущий one-click flow (уходит в checkout)
- `shopSbpPay.js` — SBP deep link flow
- `shopPayFsm.js` — FSM оплаты (DEFAULT→PROCESSING→CONFIRMED/REJECTED)
- `shopInlinePayFsm.js` (#32) — inline FSM для кнопки (ротация текстов, poll)
- `CheckoutPayButton.svelte`, `NewCardForm.svelte`

### Gaps (делать)
1. **BE: `connection_type: "Widget"` в Init** — `TbankInlineInit` / `TbankAdapter#init_payment` не передаёт `DATA.connection_type`. Добавить опциональный param.
2. **BE: widget-endpoint** — `POST /shop/api/payments/widget_init` (или расширить существующий) — сумма из БД, connection_type, JSON ответ `{ paymentUrl }`.
3. **FE: inline pay flow в RepeatSection** — сейчас `onPayCardClick()` → checkout redirect. Нужно: инлайн Init/Charge, плашка «статусы от банка», poll status.
4. **FE: fallback UI** — при REJECTED/ошибке карты: кнопки «СБП» / «карта +» прямо под карточкой.
5. **FE: expanded cards** — при клике «карта +»: список сохранённых карт из `user_cards` API + форма новой карты с toggle «сохранить для будущих заказов».
6. **FE: SBP fallback** — при клике «СБП»: SBP deep link flow для того же orderId.
7. **FE: Widget SDK inject** — ленивая загрузка `integrationjs.tbank.ru` script, `PaymentIntegration.init()`.

### Маппинг путей (CoffeeOS)

| ТЗ (шаблон) | CoffeeOS |
|---|---|
| Backend init | `app/services/payments/tbank_inline_init.rb` (+ `tbank_adapter.rb`) |
| BE endpoint | `app/controllers/shop/api/payments_controller.rb` или новый `widget_payments_controller.rb` |
| FE repeat section | `app/frontend/components/RepeatSection.svelte` |
| FE inline pay FSM | `app/frontend/lib/shopWidgetPayFsm.js` (новый) |
| FE fallback UI | `app/frontend/components/InlinePayFallback.svelte` (новый) |
| FE payment methods | `app/frontend/components/PaymentMethodsSheet.svelte` (reuse) |
| Tests BE | `test/integration/shop/api/payment_widget_init_test.rb` + `test/services/payments/tbank_inline_init_test.rb` |
| Tests FE | `test/javascript/shop_widget_pay_fsm_test.mjs` |

### Архитектура GREEN (по шагам)

| Шаг | Слой | Код (цель) | Тесты |
|-----|------|------------|-------|
| 1 | BE | `connection_type: "Widget"` в Init DATA + widget endpoint (сумма из БД, 404 missing order) | `tbank_inline_init_test.rb`, `payment_widget_init_test.rb` |
| 2 | BE | Обработка ответа Init → JSON `{ paymentUrl }`, стандартизированные ошибки (400/500) | integration test |
| 3 | FE | SDK inject + `shopWidgetPayFsm.js`: IDLE→PROCESSING→SUCCESS/ERROR | `shop_widget_pay_fsm_test.mjs` |
| 4 | FE | RepeatSection: inline pay → плашка «статусы от банка» + poll status | unit/integration |
| 5 | FE | Fallback: REJECTED → кнопки «СБП» / «карта +» inline | unit |
| 6 | FE | «карта +» → expanded saved cards + new card form с toggle | unit |
| 7 | FE | «СБП» → SBP deep link flow (reuse `shopSbpPay.js`) + iOS деградация | unit |

### Лимиты файлов / RLS
- `tbank_adapter.rb` ≈ 238 строк (>200): **не раздувать** — `connection_type` param через kwargs, без нового метода.
- `RepeatSection.svelte` ≈ 150 строк: fallback UI — отдельный компонент `InlinePayFallback.svelte`.
- Tenant: widget_init — только с shop tenant context (`Current.tenant_id`).

### Регрессия зоны
```
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb \
  test/services/shop/order_creator_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/services/payments/tbank_adapter_test.rb
```
+ JS: `node --test test/javascript/shop_widget_pay_fsm_test.mjs`

---

## Чеклист TDD (атомарно)

### Backend
- [ ] **Шаг 1** — `connection_type: "Widget"` в Init DATA + widget endpoint `POST /shop/api/payments/widget_init` (сумма из БД, 404)  
  Тесты: `tbank_inline_init_test.rb`, `payment_widget_init_test.rb`
- [ ] **Шаг 2** — Ответ Init → JSON `{ paymentUrl }` + стандартизированные ошибки  
  Тесты: integration test

### Frontend
- [ ] **Шаг 3** — SDK inject `integrationjs.tbank.ru` + `shopWidgetPayFsm.js` (IDLE→PROCESSING→SUCCESS/ERROR)  
  Тесты: `shop_widget_pay_fsm_test.mjs`
- [ ] **Шаг 4** — RepeatSection: inline pay click → плашка «статусы от банка» + disabled + poll  
  Тесты: unit
- [ ] **Шаг 5** — Fallback: REJECTED → кнопки «СБП» / «карта +» inline под карточкой  
  Тесты: unit
- [ ] **Шаг 6** — «карта +» → expanded saved cards list + NewCardForm с toggle  
  Тесты: unit
- [ ] **Шаг 7** — «СБП» → SBP deep link + iOS деградация  
  Тесты: unit

### REVIEW
- [ ] Регрессия оплаты + rubocop
- [ ] CHANGELOG / HANDOFF / SESSION_STATE итог

---

# todo — T-Bank inline payment + button statuses

**ТЗ:** [`customer_tasks/Интеграция inline-оплаты Т-Банка с динамическими статусами внутри кнопки.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md)  
**Артефакты:** `artifacts/tbank_inline_payment_button_statuses/`  
**Фаза:** PHASE 2 BUILD · Шаг 3 GREEN (готово)

---

## SPEC (канон CoffeeOS)

### Бизнес-цель
Бесшовная inline-оплата без redirect на формы Т-Банка; динамическая обратная связь на кнопке (текст/цвет/спиннер) на всех этапах банка.

### Глобальные ограничения (из ТЗ)
- Секреты `TerminalKey` / `Password` только backend ENV — не на FE, не в логах ответов API.
- Запрет redirect на внешние страницы/формы Т-Банка (в рамках этой фичи; SBP nspk — отдельный поток, не ломаем).
- BASE_URL API: `https://securepay.tinkoff.ru/v2` — не менять.
- Сигнатуры чужих эндпоинтов не трогать без нужды; для status — **расширить поведение** `GET /shop/api/payments/status/:order_id` (тот же путь, richer sync) или тонкий сервис под ним.

### Маппинг путей тестов заказчика → CoffeeOS

| ТЗ (шаблон) | CoffeeOS |
|---|---|
| `src/components/PaymentButton/__tests__/` | `test/javascript/shop_inline_pay_button_fsm_test.mjs` (+ lib `app/frontend/lib/shopInlinePayFsm.js`) |
| `src/api/payment/__tests__/` | `test/integration/shop/api/payment_status_*` / services |
| `backend/.../payment.controller.spec.ts` | `test/services/payments/tbank_adapter_test.rb`, `tbank_*_test.rb`, `test/controllers/callbacks/tbank_controller_test.rb` |
| Vitest/Jest + RTL | Node assert / Vitest-стиль `.mjs` как соседние `test/javascript/*` |
| Jest/Supertest | `bin/rails test` |

### Что уже есть (не дублировать)
- Adapter: Init, Charge, GetState, Token SHA-256, FinishAuthorize — `Payments::TbankAdapter`
- One-click: Init→Charge по RebillId — `Shop::OneClickPaymentService`
- Webhook: `Callbacks::TbankController` + idempotency + `PaymentStatusUpdater`
- Status GET: DB-only `Shop::PaymentStatusPresenter` → PENDING\|CONFIRMED\|REJECTED\|CANCELED
- Finalize: GetState sync — `POST /shop/api/orders/:id/finalize`
- FE FSM: `shopPayFsm.js` + `CheckoutPayButton.svelte` (другие лейблы/тайминги)
- 1051: `Shop::TbankPaymentError` + CLIENT_ERROR_CODES

### Gaps (делать)
1. Init **`PayType: "O"`** (двухстадийная) — сейчас нет.
2. **`POST /v2/Confirm`** при GetState=`AUTHORIZED` — метода нет; AUTHORIZED→`processing` без Confirm.
3. Status endpoint / сервис: GetState + auto-Confirm → фронту `CONFIRMED`.
4. Webhook↔polling race: усилить идемпотентность на финализации (уже lock; покрыть тестом Confirm+webhook).
5. FE: IDLE/PROCESSING ротация 1800 мс, poll 1500 мс, timeout 15 с, тексты ТЗ, reset IDLE 3 с, 1051→«Недостаточно средств».

### Архитектура GREEN (по шагам)
| Шаг | Код (цель) | Тесты |
|-----|------------|-------|
| 1 | `TbankAdapter#init_payment(pay_type:)` и/или тонкий `Payments::TbankTwoStage` — PayType O; RebillId→Charge path | `test/services/payments/tbank_adapter_test.rb` (+ optional two_stage) |
| 2 | `confirm_payment` в adapter; `Shop::InlinePaymentStatusSync` (GetState→Confirm); enrich status API | unit + `test/integration/shop/api/payment_status_*` |
| 3 | Webhook vs sync race (idempotent final) | `tbank_controller_test` / sync test |
| 4–8 | `shopInlinePayFsm.js` + wiring `CheckoutPayButton` / Checkout (не ломать 3DS/SBP) | `test/javascript/shop_inline_pay_button_fsm_test.mjs` |

### Лимиты файлов / RLS
- `tbank_adapter.rb` ≈ 238 строк (**стоп >200**): GREEN Шаг 1–2 — минимальный diff **или** новый файл `app/services/payments/tbank_confirm.rb` / `tbank_two_stage.rb` (без массового сплита без go).
- `shopPayFsm.js` — не раздувать: новая машина `shopInlinePayFsm.js` рядом.
- Tenant: status/finalize только в контексте shop tenant (`Current.tenant_id` / `X-Shop-Tenant`); webhook — как сейчас (по OrderId/PaymentId без FE secrets).

### Регрессия зоны (после GREEN шагов бэкенда/FE оплаты)
```
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb \
  test/services/shop/order_creator_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/services/payments/tbank_adapter_test.rb
```
+ JS: `node --test test/javascript/shop_inline_pay_button_fsm_test.mjs` (когда появится)

---

## Чеклист TDD (атомарно)

### Backend
- [x] **Шаг 1** — Init `PayType:"O"` / Charge при RebillId + Token SHA-256 → PaymentId  
  Тесты: `test/services/payments/tbank_adapter_test.rb` `[TDD]`  
  Статус: GREEN (PASS)
- [x] **Шаг 2** — GET status → GetState → auto Confirm на AUTHORIZED → CONFIRMED  
  Тесты: adapter Confirm + sync/status integration
- [x] **Шаг 3** — Webhook NotificationURL финализирует БД; race с polling  
  Тесты: callback + sync idempotency

### Frontend
- [ ] **Шаг 4** — IDLE → PROCESSING («Ещё чуть-чуть…»), disabled+spinner, poll 1500 мс
- [ ] **Шаг 5** — Ротация текста каждые 1800 мс (3 фазы, цикл)
- [ ] **Шаг 6** — CONFIRMED → SUCCESS («Оплачено!», зелёный, галочка), стоп таймеров
- [ ] **Шаг 7** — REJECTED/CANCELED → ERROR; 1051→«Недостаточно средств»; reset IDLE 3 с
- [ ] **Шаг 8** — Timeout 15 с → «Время ожидания истекло» → IDLE 3 с  
  Edge: HTTP 400/500 на poll → ERROR generic + reset 3 с  
  Security: FE payload/логи без TerminalKey/Password

### REVIEW
- [ ] Регрессия оплаты + rubocop зоны
- [ ] CHANGELOG / HANDOFF / SESSION_STATE итог
- [ ] MCP / ручная проверка Dev — после deploy (отдельный апрув)

---
# todo — Auth funnel cascade Flash Call×2 → SMS

**ТЗ:** [`customer_tasks/Рефакторинг воронки авторизации PWA Каскад Flash Call x2 SMS.md`](../milestones/veha_2/requirements/customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20x2%20SMS.md)  
**Артефакты:** `artifacts/auth_funnel_flash_call_x2_sms_ru/`  
**Фаза:** PHASE 1 SPEC · ждём RED

---

## SPEC (канон CoffeeOS)
### Бизнес-цель
Снижение CAC через 2-экранный Wizard и 3-уровневый каскад верификации: `Flash Call #1 → Flash Call #2 → SMS`.

### Глобальные ограничения (из ТЗ)
- нет `Email` поля, нет ручного выбора канала и нет отдельных кнопок подтверждения кода
- никаких хардкодов ключей/`api_id`/`from` — только `ENV['SMS_RU_API_ID']`, `ENV['SMS_RU_FROM']`
- dev fallback: `ENV['SHOP_OTP_LOG_FALLBACK'] = true` блокирует отправку (или передаёт `test=1`)

### План RED (что добавим тестами в PHASE 2 BUILD)
#### Backend (по `channel`)
1. `Shop::SmsRuClient`:
   - `flash_call`: `POST https://sms.ru/code/call` (проверка `json["status"] == "OK"`, upsert кода в `mobile_otp_codes`, TTL=10 мин)
   - `sms`: `POST https://sms.ru/sms/send` с последним кодом из `mobile_otp_codes` (`msg="Ваш код: XXXX"`, `from=ENV['SMS_RU_FROM']`, `ip=request.remote_ip`)
   - обработка network ошибок / JSON `status != "OK"` (API возвращает вменяемый JSON без 500)
2. `POST /shop/api/phone_otp/send`:
   - поддержка `channel: "flash_call"` и `channel: "sms"` (и одинаковая передача `request.remote_ip`)
3. `POST /shop/api/phone_otp/verify`:
   - верификация 4-значного кода (HTTP 422 для неверного кода)
4. `Rack::Attack` throttling:
   - `flash_call` кулдаун 20 сек, `sms` кулдаун 60 сек
   - при превышении частоты: HTTP 429

#### Frontend (Wizard + каскад)
1. Screen 1 (телефон):
   - mask `+7 (9XX) XXX-XX-XX`, автофокус, `Продолжить` активна строго при вводе 10 цифр
   - по клику `POST /shop/api/phone_otp/send` `channel: "flash_call"` и переход на Screen 2
2. Screen 2 (PIN):
   - 4 ячейки, авто-submit на 4-й цифре в `POST /shop/api/phone_otp/verify`
   - при HTTP 422: подсветка ячеек, shake, очистка, фокус на 1-ю
3. Каскад-таймер:
   - 0–20 сек: подсказка “последние 4 цифры…”, таймер “Ждем звонок... 00:20”
   - 20–40 сек: CTA “Запросить звонок еще раз” → повтор `flash_call` и перезапуск таймера
   - 40+ сек: CTA “Отправить код в СМС” → `sms` + кулдаун 60 сек
4. “Изменить номер”:
   - сброс таймеров каскада и состояния авторизации

### Лимиты / RLS (для реализации)
- Все BE-операции, затрагивающие shop-данные, только в контексте `Current.tenant_id` (RLS контекст на базе controllers).
- Не раздувать файлы >200 строк: `SmsRuClient` и FE FSM разбиваем по ответственности.

---

### Gate 1 (стоп)
Жду намерения на PHASE 2 BUILD (RED) для начала добавления тестов.
