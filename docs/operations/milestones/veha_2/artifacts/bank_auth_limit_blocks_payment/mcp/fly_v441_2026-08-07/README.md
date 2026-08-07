# MCP Fly v441 — #46 bank auth limit + pay *8782 (2026-08-07)

**Stand:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Release:** **v441** · tip docs `4ff0cede` (feat #46 `327e8767` + #33 `11e5eaf7`) · deployment `01KZDZ59Z9113BYEWRVEHF3QBT`  
**Evidence JSON:** [`fly_mcp_bank_auth_limit_2026-08-07.json`](./fly_mcp_bank_auth_limit_2026-08-07.json)

## Deploy health

| Check | Result |
|---|---|
| Fly machines VERSION 441 started | **PASS** |
| `/up` | **PASS** 200 green |
| Checkout chunk `#46` markers | **PASS** |

## Verdict

| Check | Result |
|---|---|
| *5953 → ErrorCode 119 friendly + NewCardForm (не «Сбой банка: позже») | **PASS** |
| *8782 → оплата ok → статусы «Оплачен» | **PASS** |

## Notes

- Deploy пользователя: v441 (после v440); инфраструктура нормальная.
- Цель заказчика «заместить статусы» — достигнута оплатой *8782 (`order_id=db45ab5f-…`).
