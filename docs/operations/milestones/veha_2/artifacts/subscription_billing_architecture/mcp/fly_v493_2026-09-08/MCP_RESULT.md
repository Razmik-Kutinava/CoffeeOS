# MCP — #78 slice-5 recheck · Fly v493 · 2026-09-08

**Вердикт: PARTIAL** (API + seed plan PASS · live Charge SKIP)

| Step | Result |
|------|--------|
| Seed `pilot_weekly` | **PASS** id `9862ce39-…` price 499 |
| POST create path | plan found |
| Live Charge | **SKIP** · T-Bank **ErrorCode 223** «Неверные параметры» на 3 test Rebill (`*@coffeeos.dev`) — не карты Арама |
| 401/404/501 | PASS (v490) |

Нужен свежий RebillId (новая привязка карты test-guest) для полного PASS purchase.
