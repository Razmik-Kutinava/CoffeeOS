# #73 MCP Point A — Fly v460 — Fiscal receipts ЛК

**Дата:** 2026-08-28  
**Fly deploy:** **v460** · `deployment-01M13JTWPKPJBB3YCG2ZGMWP5P`  
**Browser:** cursor-ide-browser  
**Live fiscal notify:** **нет** (`FiscalReceipt.unscoped.count == 0` на Fly)

## Вердикт: PARTIAL

Код/webhook path на v460; live RECEIPT + UI «Чек» — **SKIP** до fiscal notifications ON в кабинете Т-Банка + успешной оплаты.

| # | Result | Notes |
|---|--------|-------|
| F0 fiscal notify ON | **SKIP** | ops: кабинет терминала → уведомления о фискализации на `…/callbacks/tbank` |
| F1 до чека (forming) | **SKIP** | нет свежего tbank-заказа в сессии |
| F2 Neon fiscal_receipts | **SKIP** | `count=0` на Fly (ssh runner) |
| F3 UI ссылка Чек | **SKIP** | зависит от F0–F2 |
| F4 no eternal forming | **PASS** | guest `#/orders` без broken state; `06_orders_lk.png` |
| F5 Retry idempotency | **SKIP** | нет live RECEIPT (local/CI покрыто) |
| F6 payment webhook | **PASS** | invalid Token → **401** |
| F7 success body **OK** | **PASS*** | канон v459 Rack + код v460; live bank не гоняли |
| Smoke UI Point A | **PASS** | shop + barista board; `04_barista_board.png` |
| УК лента | **PASS** | табло 0/6 сегодня |

## Open для владельца

1. В кабинете Т-Банка включить **уведомления о фискализации** на `https://coffeeos.fly.dev/callbacks/tbank`.
2. Live pay test-customer → RECEIPT → ЛК «Чек» + строка в `fiscal_receipts`.
