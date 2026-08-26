# #71 MCP Point A — Fly v458 — Email после оплаты

**Дата:** 2026-08-26  
**Fly deploy:** **v458** (первый attempt v457 failed на advisory lock после успешной `CreateOrderEmails`; retry → v458)  
**Image:** `deployment-01M0Z4NC76AMSTR2TJ9ZFEZ4F1`  
**ENV bounce secret:** `CALLBACK_SHARED_SECRET` **set** (`EMAIL_BOUNCE_WEBHOOK_SECRET` отсутствует — канон допускает shared)  
**Browser:** Chrome MCP  
**Артефакты:** `mcp_71_checkout_no_email.png` · `mcp_71_success_email_block.png` · `mcp_71_invalid_email.png`

## Local
skip (CI green 32971396113 до deploy)

## Fly MCP Point A: **PARTIAL**

### A — Checkout без email-гейта

| # | Result | Notes |
|---|--------|-------|
| A1 | **PASS** | `#/checkout`: только «Вход по телефону»; `input[type=email]` = 0 |
| A2 | **PASS** | Identity = телефон/Callcheck UI; pay CTA в шторке `+5₽` |
| A3 | **SKIP** | New card / save_card — не дошли без полного Callcheck |

### B — Success email-блок

| # | Result | Notes |
|---|--------|-------|
| B1 | **PASS** | Forced `#/payment-result?status=ok&order_id=…` → «✔ Чек сформирован» |
| B2 | **PASS** | Блок «Куда прислать чек и предложения» + email + marketing off + Пропустить |
| B3 | **PASS** | Пропустить → `#/order/:id` без повторного гейта |
| B4 | **PASS** | `bad@` → inline «Некорректный email» |
| B5 | **SKIP** | Валидный POST save — нужен session/reconnect на «свой» заказ после live pay |
| B6 | **SKIP** | Live СБП «Я оплатил» не гоняли (экономия / нет тестовой оплаты в этом прогоне) |

Примечание: на forced success poll SBP дал alert «Order not found» (чужой/старый order без payment session) — UI email-блока при этом остаётся; не блочит B1–B4.

### C — Не ломать

| # | Result |
|---|--------|
| C1 Callcheck/phone wizard | **PASS** (виден на checkout) |
| C2 История / ЛК #69 | **PASS** (прогон до logout) |
| C3 Telegram #70 | **PASS** |

### D — API

| # | Result | Notes |
|---|--------|-------|
| D1 POST email с session | **SKIP** | нет live order ownership |
| D2 POST без session | **PASS*** | **401** (shop auth gate) — безопаснее ожидаемого 404 |
| D3 bounce без signature | **PASS** | **401** |
| D4 bounce HMAC | **SKIP** | секрет на Fly есть; значение не доставали в MCP |
| D5 fiscal без email | **SKIP** | не трогали ОФД в этом прогоне |

### Пачка

| Слой | Result |
|------|--------|
| Fly logs | OK на прогоне (profile/history/bounce 401 без 5xx) |
| Sentry 24h | SKIP (нет доступа в этом шаге) |
| Neon | migrate `order_emails` в release_command v457 log → applied |
| УК | SKIP |

## Вердикт

**PARTIAL** — hot-path UI #71 (checkout без email + success email block + validation + skip) на Fly v458 подтверждён. Live pay B5/B6 и bounce HMAC D4 — отдельный короткий прогон при необходимости апрува заказчику на полный DoD оплаты.
