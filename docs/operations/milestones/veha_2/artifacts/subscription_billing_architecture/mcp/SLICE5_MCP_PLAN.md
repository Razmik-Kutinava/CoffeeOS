# MCP — #78 slice-5 Shop API (после deploy)

| | |
|---|---|
| **IN** | GET/POST/PATCH subscriptions · 501 cancel/confirm · anti-duplicate |
| **OUT** | Slice 6 PWA · Slice 2 usage · Slice 3/4 real cancel/renewal |
| **Коммиты** | GREEN `c4e48db8` · fix `1f433a75` · CI [34224418988](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34224418988) |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Артефакт** | `mcp/fly_vNNN_YYYY-MM-DD/MCP_RESULT.md` + `mcp_result.json` |

## Чеклист

| # | Шаг | PASS |
|---|-----|------|
| 0–1 | deploy + `/up` | live + 200 |
| 2 | test-guest session | cookie |
| 3 | GET current без sub | **404** |
| 4 | GET без session | **401** |
| 5 | POST create (RebillId) | **201** active **или SKIP**+доказательство |
| 6 | GET current after | 200 + fields |
| 7 | technical order | **`closed`** (не barista board) |
| 8 | PATCH auto_renew | persisted |
| 9–10 | cancel / confirm_payment | **501** slice 3/4 |
| 11 | duplicate POST | **422** |
| 12 | inactive PM | **422** |
| 13 | #77 config/profile | keys present |
| 14 | UserCards smoke | 200 |

## Не ломать

Checkout / cards · webhook → closed · #77 offer keys · callback idempotency.
