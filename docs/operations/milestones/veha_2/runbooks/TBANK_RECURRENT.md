# Т-Банк: рекуррентные платежи и привязка карты (B1.12)

**Статус:** **rev2 R1+R2+R3** `[x]` OPS_PASS 2026-06-24 · Fly MCP 9/10 (RSA хвост) · legacy v1 R1–R6 OPS_PASS  
**ТЗ:** [`B1_12_recurrent_payments.md`](../requirements/customer_tasks/B1_12_recurrent_payments.md)  
**Связано:** §2.3 (базовая оплата) · `Payments::TbankAdapter` · `POST /callbacks/tbank`

---

## Ревизия 2 (канон заказчика 2026-06-24)

| Параметр | Значение |
|----------|----------|
| Сценарий | **nonPCI** — кастомная форма + RSA CardData |
| Первая оплата | Init → **FinishAuthorize** (не redirect на PaymentURL) |
| Повторная | Init → Charge по RebillId |
| UI | Макеты [`8925`](../artifacts/demo-feedback/screenshots/1000008925.png) (форма) · [`8924`](../artifacts/demo-feedback/screenshots/1000008924.png) (способы оплаты) |
| FSM кнопки | Состояния **0–7** |
| Блокеры docs | Q-R2-1..3 **`[x]`** 2026-06-24 · gate [`b112_r3_phase0_gate_2026-06-24.json`](../artifacts/demo-feedback/b112_r3_phase0_gate_2026-06-24.json) |

**Артефакты rev2:**
- [`b112_revision2_stage0_scope_2026-06-24.json`](../artifacts/demo-feedback/b112_revision2_stage0_scope_2026-06-24.json)
- [`b112_tbank_nonpci_review_2026-06-24.json`](../artifacts/demo-feedback/b112_tbank_nonpci_review_2026-06-24.json)

### nonPCI — сверка с докой (кратко)

| Шаг | API Т-Банка | CoffeeOS |
|-----|-------------|----------|
| CardData | `PAN=…;ExpDate=…;CardHolder=…;CVV=…` → RSA-2048 → Base64 | **R2 `[x]`** `NewCardSheet` + `tbankCardEncrypt.js` |
| Публичный ключ | ЛК Т-Бизнес → Магазины → терминал | **R2 `[x]`** `TBANK_RSA_PUBLIC_KEY` · `GET /payments/card_config` |
| Новая карта | Init + FinishAuthorize | **R1 `[x]`** `POST /shop/api/payments/new_card` |
| 1 клик | Init + Charge | **R1 `[x]`** `POST /shop/api/payments/one_click` |
| 3DS | `3DS_CHECKING` → ACSUrl, PaReq, MD | **R1 `[x]`** API · **R3 `[x]`** `ThreeDsOverlay` iframe |
| Ошибки | ErrorCode в ответе | **R1 `[x]`** · **R3 `[x]`** FSM 5–7 |

Официально: [FinishAuthorize](https://developer.tinkoff.ru/eacq/api/finish-authorize)

---

## Scope без изменений (Q2, Q3, Q4, Q7)

| Параметр | Значение |
|----------|----------|
| Банк | Т-Банк |
| Карт на пользователя | Все храним; **главная** = последняя успешная оплата |
| Рекуррент | Только **card** (СБП — позже) |
| Идентификация | Verified email (B1.7) |
| Храним в БД | rebill_id, card_id, masked pan, exp, brand |
| Не храним | PAN, CVV/CVC |

---

## Подзадачи rev2

> **Workflow:** один документ заказчика = один `go` = один R = commit/ops/стоп. Апрув эпика — после R3.

| ID | Что | `go` | Зависимости |
|----|-----|------|-------------|
| **R1** | UserCards, FinishAuthorize, Charge API, 3DS proxy, ErrorCode | **`[x]`** 2026-06-24 | Q-R2-1 |
| **R2** | Кастомная форма + RSA (8925) | **`[x]`** 2026-06-24 | R1 `[x]` · Q-R2-2 default on |
| **R3** | FSM 0–7 + экран 8924 | **`[x]`** 2026-06-24 | R1+R2 `[x]` |

---

## Legacy v1 (iframe + webhook) — справочно

Реализовано 2026-06-18…21: Init → payment_url, webhook → SavedCardStore, Charge, iframe, R4–R6.  
**Не соответствует** ТЗ v2 заказчика. См. секцию legacy в ТЗ.

### Fly MCP rev2 R3 (канон)

```bash
# Windows (flyctl в PATH):
#   $env:FLY_BIN = "C:\Users\darks\.fly\bin\flyctl.exe"
ruby bin/b112_r3_one_click_prep_fly.rb
node bin/b112_r3_fsm_mcp.mjs
```

Артефакты: `b112_r3_fsm_ops_pass_*.json` · скрины `screenshots/b112_r3_fsm_*`

### Fly MCP v1 (устарели для приёмки rev2)

```bash
ruby bin/b112_r3_one_click_prep_fly.rb && node bin/b112_r3_one_click_mcp.mjs
```

Регрессия зоны: `bin/rails test test/integration/shop/api/qa_section_2_3_*` + `b112_*`

---

## Секреты / ENV

Существующие: `TBANK_TERMINAL_KEY`, `TBANK_PASSWORD`, `TBANK_RETURN_URL` — см. [`FLY_DEMO_STAND.md`](../../demo/FLY_DEMO_STAND.md)

**План rev2:** `TBANK_RSA_PUBLIC_KEY` — публичный ключ терминала для CardData (не в git).

```bash
fly secrets set TBANK_RSA_PUBLIC_KEY="$(cat tbank_public.pem)" -a coffeeos
```

Проверка: `GET /shop/api/payments/card_config` → `card_data_ready: true`.  
Док: [`FLY_DEMO_STAND.md`](../../demo/FLY_DEMO_STAND.md) § «Секреты Fly».

**CardHolder (R2 хвост):** поле в форме 8925 нет — берётся из **имени на checkout** (`cardHolderName={name}` в `NewCardSheet`).

---

## Приёмка rev2 (после кода)

| Артефакт | Подзадача |
|----------|-----------|
| `b112_r1_nonpci_ops_pass_*.json` | R1 |
| `b112_r2_custom_card_ops_pass_*.json` | R2 |
| `b112_r3_fsm_ops_pass_*.json` | R3 |

**Следующий шаг:** апрув заказчика на эпик B1.12 rev2 · при необходимости `fly secrets set TBANK_RSA_PUBLIC_KEY`.
