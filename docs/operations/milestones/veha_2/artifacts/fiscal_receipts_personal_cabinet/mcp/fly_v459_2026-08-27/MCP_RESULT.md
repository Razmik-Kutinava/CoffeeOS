# #73 MCP Point A — Fly v459 — Fiscal receipts ЛК

**Дата:** 2026-08-27  
**Fly deploy:** **v459** · `deployment-01M11RD5W850BADA7T5CS7C5Q5`  
**Browser:** cursor-ide-browser  
**Live fiscal notify:** **нет** (`FiscalReceipt.unscoped.count == 0` на Fly)

## Вердикт: PARTIAL

Код/webhook path на стенде; live RECEIPT + UI «Чек» — SKIP до включения fiscal notifications в кабинете Т-Банка + успешной оплаты.

| # | Result | Notes |
|---|--------|-------|
| F0 fiscal notify ON | **SKIP** | ops-блокер владельца: кабинет терминала → уведомления о фискализации на `…/callbacks/tbank` |
| F1 до чека (forming) | **SKIP** | нет свежего tbank-заказа под test-customer; гость → чужой order = «Не удалось загрузить заказ» (ожидаемо) |
| F2 Neon fiscal_receipts | **SKIP** | 0 рядов на Fly; notify не приходил |
| F3 UI ссылка Чек | **SKIP** | зависит от F0–F2 |
| F4 наличные / no eternal forming | **PASS*** | код: `fiscal_expected` только если payment `provider==tbank`; guest `#/orders` без broken «Чек формируется» |
| F5 Retry unique ofd_receipt_id | **SKIP** | нет live RECEIPT (покрыто local/CI ранее) |
| F6 payment webhook CONFIRMED path | **PASS** | live bank REJECTED → enqueue + **200**; invalid Token → **401** JSON |
| F7 success body **OK** | **PASS** | Rack на Fly: `[200, "OK", "text/plain; charset=utf-8"]` (Status=NEW ignored) |
| Smoke UI Point A | **PASS** | каталог / barista board |
| УК лента | **PASS** | Point A табло 0 сегодня/вчера — ок |

## Open для владельца
1. В кабинете Т-Банка включить **уведомления о фискализации** на NotificationURL `https://coffeeos.fly.dev/callbacks/tbank`.
2. Прогнать live pay test-customer → дождаться RECEIPT → проверить ЛК «Чек» + `fiscal_receipts`.
