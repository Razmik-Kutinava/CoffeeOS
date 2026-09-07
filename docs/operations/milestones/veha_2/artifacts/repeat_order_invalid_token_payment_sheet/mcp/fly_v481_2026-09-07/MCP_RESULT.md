# MCP Point A — #26 step5 inline pay error · Fly **v481** · 2026-09-07

**App:** https://coffeeos.fly.dev  
**Release:** **v481** · tip `a9148d9b`  
**Tenant:** Point A  
**Вердикт:** **PARTIAL** — M2 (P0) **не закрыт**: у MCP-гостя `da143c8c-…` **нет** `MobilePaymentMethod` / saved cards в шторке (только СБП + «Картой +»).

| ID | Сценарий | Результат | Evidence |
|----|----------|-----------|----------|
| M1 | открыть «Способ оплаты» | **PASS** | `01_sheet_open_before_pay.png` · sheet · без inline error |
| M2 | отказ банка → inline | **SKIP / BLOCKER** | нет saved card для one-click decline |
| M3 | CTA после отказа | **SKIP** | зависит от M2 |
| M4 | «Картой +» | **PASS** | NewCardForm открывается вручную |
| M5 | X close | **PASS** | `payment-methods-close` закрывает sheet |
| M6 | happy-path | **SKIP** | не гоняли live charge |

**DoD M2:** не PASS в этой сессии — нужен guest с картой / *5953-like decline.

**Fly MCP:** **PARTIAL**
