# todo — T-Kassa SBP Autopay AccountToken (#34)

**ТЗ:** [`customer_tasks/Интеграция Автоплатежей СБП Т-Касса в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20Автоплатежей%20СБП%20Т-Касса%20в%20PWA.md)  
**Артефакты:** `artifacts/tbank_sbp_autopayments_account_token/`  
**Фаза:** PHASE 3 REVIEW · закрыт (Checkout UI backlog)

---

## SPEC (канон CoffeeOS)

### Бизнес-цель
Zero-Click checkout для постоянных гостей: первая оплата СБП с привязкой счёта (`AccountToken`) → повторные оплаты через `ChargeQr` без ухода в банк; при soft-decline — fallback на обычный СБП deep link **без** удаления токена.

### Глобальные ограничения (из ТЗ)
- Сумма заказа **только** на бэкенде (из БД по order), не с FE.
- Пароль терминала / Token SHA-256 — **только** backend ENV (`TBANK_*`).
- `AccountToken` **не** удалять при soft decline (нет средств, лимиты); удаление — явная отвязка или fatal («счёт закрыт»).
- Без сторонних SDK для `GetAddAccountQRState` / `ChargeQr` — прямые HTTP в `TbankAdapter` (или соседний сервис).
- Hot-path: `order_creator`, `tbank_adapter`, `tbank_controller` — минимальный diff.

### Что уже есть (не дублировать)
| Компонент | Путь | Роль |
|---|---|---|
| Init + Token SHA-256 | `Payments::TbankAdapter` | `init_payment`, `build_token`, `verify_notification` |
| Charge (карта RebillId) | `TbankAdapter#charge` / `#charge_recurrent` | **не** ChargeQr |
| GetQr → deep link | `Payments::TbankQrFetcher` + `Shop::SbpPaymentInitiator` | manual SBP, `recurrent: false` |
| SBP FE | `shopSbpPay.js`, Checkout SBP path | `POST /shop/api/payments/sbp/init` |
| Webhook + idempotency | `Callbacks::TbankController` + `TbankCallbackJob` | по `PaymentId:Status`; RebillId → `SavedCardStore` |
| UserCards schema | `mobile_payment_methods` | `payment_type` ∈ `card\|sbp\|ya_pay`; `card_token` = RebillId для card |
| One-click карта | `Shop::OneClickPaymentService` | Init→Charge(RebillId) — паттерн для ChargeQr |

### Gaps (делать)
1. **BE API methods:** `GetAddAccountQRState`, `ChargeQr` (новые методы; `tbank_adapter.rb` уже **260** строк → **не раздувать** — вынести в `Payments::TbankSbpAutopay` или тонкие wrappers рядом).
2. **BE Setup:** Init SBP с `Recurrent=Y` + `DATA={"QR":"true"}` при `save_sbp_account: true` (расширить `SbpPaymentInitiator` / отдельный сервис).
3. **BE storage:** `AccountToken` в `mobile_payment_methods` (`payment_type: "sbp"`, `card_token` = AccountToken); идемпотентность по `RequestKey` (Redis key или колонка + unique).
4. **BE webhook:** после успеха + `RequestKey` → `GetAddAccountQRState` → persist AccountToken (массив = несколько строк MPM на customer).
5. **BE charge:** `POST /shop/api/payments/sbp/charge` (маппинг ТЗ `/api/payments/charge`) — сумма из order, Init→ChargeQr; ошибки: network vs `CHARGE_DECLINED` (+ fatal flag).
6. **FE Setup:** чекбокс «Привязать счет…» + `save_sbp_account`; toast «Сервис временно недоступен» на 4xx/5xx.
7. **FE Zero-Click:** дефолт «Ваш счет СБП» если есть token; fullscreen loader → success / toast reconnect.
8. **FE Fallback:** `CHARGE_DECLINED` → toast + manual `sbp/init` без bind; token не трогать (soft).

### Маппинг путей (ТЗ → CoffeeOS)

| ТЗ (шаблон) | CoffeeOS |
|---|---|
| `POST /api/payments/init` | `POST /shop/api/payments/sbp/init` (+ `save_sbp_account`) **или** отдельный `sbp/bind_init` |
| `POST /api/payments/charge` | `POST /shop/api/payments/sbp/charge` (новый) |
| Webhook NotificationURL | `Callbacks::TbankController` (+ ветка RequestKey / AccountToken) |
| AccountToken storage | `mobile_payment_methods` `payment_type=sbp` + `card_token` |
| Backend tests | `test/services/payments/tbank_sbp_autopay_test.rb`, `test/services/shop/sbp_*_test.rb`, `test/integration/shop/api/sbp_autopay_*_test.rb`, `test/controllers/callbacks/tbank_controller_test.rb` |
| Frontend tests | `test/javascript/shop_sbp_autopay_*.mjs` (`node --test`) |
| Vitest/React/`src/…` | **не использовать** — канон Rails + Svelte + `node --test` |

### Архитектура GREEN (по шагам ТЗ)

| Шаг | Слой | Код (цель) | Тесты (RED→GREEN) |
|-----|------|------------|-------------------|
| 1 Setup | BE+FE | `save_sbp_account` → Init Recurrent+QR → GetQr deep link; checkbox + toast 4xx/5xx | adapter/initiator unit + sbp_init integration + JS checkbox/toast |
| 2 Webhook | BE | verify → `GetAddAccountQRState` → append AccountToken; idempotent `RequestKey`; HTTP 200 | callback + store idempotency tests |
| 3 Zero-Click | BE+FE | `sbp/charge` Init→ChargeQr; UI default SBP account + loader → paid | charge service + API + JS FSM |
| 4 Fallback | BE+FE | `CHARGE_DECLINED` (+ soft/fatal); toast + manual init; token keep on soft | decline mapping + FE state machine |

### Storage / Migration Gate
- **Предпочтительно без DDL:** reuse `mobile_payment_methods` (`payment_type: sbp`, `card_token` = AccountToken). Несколько счетов = несколько строк.
- **Идемпотентность RequestKey:** Redis `tbank:sbp_account:#{RequestKey}` (как callback PaymentId) **или** колонка `external_request_key` + unique — **DDL только после явного go**.
- Fatal «счёт закрыт» → `is_active=false` (не hard delete), если Т-Касса отдаёт fatal code.

### Лимиты файлов / RLS
| Файл | Сейчас | Правило |
|---|---|---|
| `tbank_adapter.rb` | ~260 (>200) | **не добавлять** ChargeQr/GetAddAccountQRState внутрь монолита — новый `payments/tbank_sbp_autopay.rb` (или 2 тонких метода max + go на сплит) |
| `Checkout.svelte` | ~670 | UI чекбокс/метод — partial / lib, не раздувать route |
| `shopSbpPay.js` | ~162 | autopay FSM → `shopSbpAutopay.js` (новый) |
| Tenant | — | все shop endpoints с `Current.tenant_id` / RLS как существующие payments |

### Риски / блокеры
| Риск | Влияние |
|---|---|
| Терминал T-Bank: Charge/Recurrent **сейчас заблокирован** (#32 error 10) | Live MCP SUCCESS #34 тоже blocked до включения методов в ЛК; код+моки — да |
| `GetAddAccountQRState` / `ChargeQr` — нет в текущем adapter | Нужны официальные контракты T-Bank (поля ответа) |
| Путаница с #27/#33 card RebillId | Жёстко: SBP AccountToken ≠ card RebillId; разные `payment_type` |

### Регрессия зоны (после GREEN)
```
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb \
  test/services/shop/order_creator_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/services/payments/tbank_adapter_test.rb \
  test/integration/shop/api/sbp_payment_init_test.rb
```
+ JS: `node --test test/javascript/shop_sbp_*.mjs`

### Exit Criteria (CoffeeOS)
1. Тесты шагов 1–4 зелёные + регрессия зоны PASS.
2. Rubocop на изменённом Ruby; JS без падений `node --test`.
3. AccountToken persist (MPM `sbp`) + idempotent RequestKey.
4. ENV уже `TBANK_TERMINAL_KEY` / `TBANK_PASSWORD` — сверить `.env.example` (не дублировать `TERMINAL_*` из шаблона ТЗ).

---

## Чеклист шагов

- [x] **Шаг 1:** Setup — Init+Recurrent+QR + checkbox `save_sbp_account` + toast (BE+FSM; Checkout UI checkbox — backlog до REVIEW)
- [x] **Шаг 2:** Webhook — GetAddAccountQRState + AccountToken + RequestKey idempotency
- [x] **Шаг 3:** Zero-Click — `sbp/charge` ChargeQr + UI loader/success FSM
- [x] **Шаг 4:** Fallback — `CHARGE_DECLINED` soft/fatal + FSM declined→manual

---

## Статус

| Фаза | Статус |
|---|---|
| PHASE 0 intake | `[x]` `48aba0c6` |
| PHASE 1 SPEC | `[x]` |
| PHASE 2 RED | `[x]` `e1d73dc5` |
| PHASE 2 GREEN | `[x]` `1268bb45` |
| PHASE 3 REVIEW | `[x]` ownership+settle |
