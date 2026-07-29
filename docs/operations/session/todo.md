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
# todo — Auth funnel cascade Flash Call×2 → SMS.ru

**ТЗ:** [`customer_tasks/Рефакторинг воронки авторизации PWA Каскад Flash Call x2 SMS на базе SMS.ru.md`](../milestones/veha_2/requirements/customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20x2%20SMS%20на%20базе%20SMS.ru.md)  
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
