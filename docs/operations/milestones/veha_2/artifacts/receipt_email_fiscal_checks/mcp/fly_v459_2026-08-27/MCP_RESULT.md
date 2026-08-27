# #72 MCP Point A — Fly v459 — Receipt.Email/Phone

**Дата:** 2026-08-27  
**Fly deploy:** **v459** · `deployment-01M11RD5W850BADA7T5CS7C5Q5` · HEAD `0609ae6b`  
**Browser / tools:** cursor-ide-browser  
**Live pay:** no (банк в логах `ErrorCode 1051` REJECTED на чужих Init; в этой сессии live Init не гоняли)

## Вердикт: PARTIAL

UI/smoke + код на релизе ок; live Init/доставка чека кассой — SKIP.

| # | Result | Notes |
|---|--------|-------|
| P0 `/up` | **PASS** | 200 |
| P1 Point A shop | **PASS** | каталог + корзина; `01_shop_point_a.png` |
| P2 release ≥ #72 | **PASS** | v459; `TbankReceiptBuilder.for_order!` → `/rails/app/services/payments/tbank_receipt_builder.rb:25` |
| P3 ENV ОФД | **PASS*** | дефолты/`TbankReceiptBuilder` на образе; secrets не дампили |
| P4 ≠ #71 | **PASS** | checkout только телефон; email-гейт на pay нет |
| A1–A2 | **PASS** | `#/checkout` phone + CTA `+5₽`; categories API 200 |
| B1–B4 live Init/Phone | **SKIP** | live pay не выполняли (safety + 1051 в логах стенда) |
| C1–C4 Email priority | **SKIP** | нет live test-customer с email в этой сессии |
| D1 код на релизе | **PASS** | ReceiptBuilder на Fly |
| D2 mailer ≠ ОФД | **PASS** | #71 UI-блок отдельно; Receipt = Init |
| D3 confirm без Receipt | **PASS** | по канону docs/коду |
| D4 Cancel без Receipt | **n/a** | не трогали |
| E1 Callcheck/phone | **PASS** | wizard на checkout |
| E2 #71 email-блок | **n/a** | без success screen |
| E3 #69 ЛК | **PASS** | `#/orders` «Сегодня заказов пока нет» |
| E4 Cancel #40 | **n/a** | |
| Sentry 24h | **skip** | нет Sentry MCP в сессии |
| Fly logs | **PASS** | после boot Puma listening; нет `TbankReceiptBuilder` Exception в срезе |
| Neon | **PASS*** | через `fly ssh` (MCP postgres = `coffeeos_development`, не prod) |
| УК Point A | **PASS** | barista board Point A, лента сегодня 0/6; старые pending не чинили |

## Open
- Live Init + факт доставки чека кассой (B/C) — после test-customer pay.
- `card_hash:apply` / backfill — отдельный апрув (#74).
