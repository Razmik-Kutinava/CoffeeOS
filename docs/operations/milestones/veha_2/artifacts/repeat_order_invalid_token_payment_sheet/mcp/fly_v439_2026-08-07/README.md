# MCP Fly v439 — #26 G7 + G1–G4 (2026-08-07)

**Stand:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Release:** **v439** · commit `bd0e9fb0` · deployment `01KZDEN9MV9QW2DKFWQXRNFYVT`  
**Evidence JSON:** [`fly_mcp_repeat_invalid_token_2026-08-07.json`](./fly_mcp_repeat_invalid_token_2026-08-07.json)

## Verdict

| Check | Result |
|---|---|
| Deploy /up | **PASS** |
| G1 labels `Картой *XXXX` | **PASS** (*5953 / *8782) |
| G2 orange «Оплатить» | **PASS** (`#ff8c42`) |
| G3 «Картой +» + form | **PASS** |
| G4 СБП disabled | **PASS** |
| G7 live insufficient → NewCardForm | **PARTIAL** (банк rate-limit → BANK_ERROR; unit+bundle PASS) |

## Notes

- Скрин viewport sheet сохранён в сессии MCP (chat); файл PNG в artifacts не писался из-за sandbox chrome-devtools path.
- Live pay *5953: inline «Превышено допустимое количество запросов авторизации» · fsm=6 — не сценарий insufficient funds.
