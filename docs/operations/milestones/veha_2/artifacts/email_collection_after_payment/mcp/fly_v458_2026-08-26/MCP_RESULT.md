# #71 MCP Point A — Fly v458 — Email после оплаты

**Дата:** 2026-08-26 (догон API без live pay)  
**Fly deploy:** **v458** · `deployment-01M0Z4NC76AMSTR2TJ9ZFEZ4F1`  
**ENV bounce secret:** `CALLBACK_SHARED_SECRET` **set**  
**Browser:** Chrome MCP  
**Артефакты:** `mcp_71_checkout_no_email.png` · `mcp_71_success_email_block.png` · `mcp_71_invalid_email.png`

## Local
skip (CI green 32971396113 до deploy)

## Fly MCP Point A: **PASS** (без live pay)

B5/B6 (живая оплата/СБП) по-прежнему **SKIP** — вне этого прогона.

### A — Checkout без email-гейта

| # | Result | Notes |
|---|--------|-------|
| A1 | **PASS** | `#/checkout`: только «Вход по телефону»; `input[type=email]` = 0 |
| A2 | **PASS** | Identity = телефон/Callcheck UI; pay CTA в шторке `+5₽` |
| A3 | **PASS*** | Чекбокс «Сохранить карту…» / `save_card` **есть в Fly bundle** `application-ClUDWKOX.js`. Интерактивный toggle — после Callcheck (не live pay); UI до телефона не открывает NewCardForm |

### B — Success email-блок

| # | Result | Notes |
|---|--------|-------|
| B1 | **PASS** | Forced `#/payment-result?status=ok&order_id=…` → «✔ Чек сформирован» |
| B2 | **PASS** | Блок «Куда прислать чек и предложения» + email + marketing off + Пропустить |
| B3 | **PASS** | Пропустить → `#/order/:id` без повторного гейта |
| B4 | **PASS** | `bad@` → inline «Некорректный email» |
| B5 | **SKIP** | Live pay (намеренно) |
| B6 | **SKIP** | Live СБП (намеренно) |

### C — Не ломать

| # | Result |
|---|--------|
| C1 Callcheck/phone wizard | **PASS** |
| C2 История / ЛК #69 | **PASS** |
| C3 Telegram #70 | **PASS** |

### D — API (догон 2026-08-26, без live pay)

| # | Result | Notes |
|---|--------|-------|
| D1 POST email + reconnect_token | **PASS** | `POST /shop/api/orders/:id/email?tenant_id=PointA` + `X-Shop-Api-Key` + `reconnect_token` → **200** `{success:true, queued_receipt:true}` (email `mcp71-ext-…@example.com`). Также `Orders::EmailService` на Fly → success. Важно: без `tenant_id` query — fallback на `test-cafe` → ложный 404 |
| D2 без token (с API key) | **PASS** | **404** `Order not found`. Без API key — **401** (auth gate) |
| D3 bounce без signature | **PASS** | **401** |
| D4 bounce HMAC | **PASS** | `X-Webhook-Signature` HMAC-SHA256(`CALLBACK_SHARED_SECRET`, body) → **200** `{success:true, updated:1}`; `order_emails.status=bounced`, `bounce_reason=mailbox_full` |
| D5 fiscal ≠ email | **PASS*** | `Orders::EmailService` **не** трогает `FiscalReceipt`. Point A demo: `fiscal_receipts` count=0 (ОФД stub на receipt UI). Таблицы независимы; email-канал не гейтит кассовый чек |

### Пачка

| Слой | Result |
|------|--------|
| Fly logs | OK: EmailController 200/404, EmailBounce updated=1, receipt mailer job |
| Sentry 24h | SKIP |
| Neon | `order_emails` live после migrate v457/v458 |
| УК | SKIP |

## Вердикт

**PASS (без live pay)** — A1–A3*, B1–B4, C, D1–D5 закрыты на Fly v458.  
Остаётся только **живая оплата** B5/B6 при полном DoD заказчику.
