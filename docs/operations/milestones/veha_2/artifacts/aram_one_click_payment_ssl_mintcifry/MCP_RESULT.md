# MCP Fly v435 — #45 Aram one-click SSL + Charge

**Дата:** 2026-08-06  
**Fly:** v435 · `deployment-01KZB0QYSKZM6BWWCVR840SNS4` · commit `8db2bed2`

## Root cause

Т-Банк перевёл API на **Russian Trusted Root CA (НУЦ Минцифры)**. В Docker на Fly CA не было → `certificate verify failed` → `widget_init` не писал `provider_payment_id`.

## Evidence

| Check | Result |
|-------|--------|
| SSL + Charge *5953 (server) | **PASS** PaymentId `8995036222` → `#202608-0013` |
| MCP UI one-click click | **PASS** «✔ Оплачено!» → `#202608-0014` accepted / tbank `8995082965` |
| Unit/integration | 13 runs PASS · JS 2/2 PASS |

JSON server: [`mcp_fly_v435_2026-08-06.json`](./mcp_fly_v435_2026-08-06.json)  
JSON UI: [`mcp_fly_v435_ui_one_click_2026-08-06.json`](./mcp_fly_v435_ui_one_click_2026-08-06.json)  
Screenshot: [`mcp/ui_one_click_success_v435.png`](./mcp/ui_one_click_success_v435.png)
