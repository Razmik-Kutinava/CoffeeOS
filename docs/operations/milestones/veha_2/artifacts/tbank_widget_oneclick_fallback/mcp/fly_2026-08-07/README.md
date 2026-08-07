# MCP Fly v440 — #33 fallback vs expanded + #46 deploy (2026-08-07)

**Stand:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Release:** **v440** · commit `11e5eaf7` · deployment `01KZDYQPQCHWPFBPEX3XJF8JKA`  
**Evidence JSON:** [`fly_mcp_fallback_expanded_2026-08-07.json`](./fly_mcp_fallback_expanded_2026-08-07.json)

## Verdict

| Check | Result |
|---|---|
| Push `11e5eaf7` | **PASS** |
| Deploy /up | **PASS** (200) |
| Bundle helpers (`El`/`Dl` = decline/plus UI) | **PASS** |
| S1: после отказа — статус + «СБП»/«карта +», **без** списка карт | **PASS** |
| S2: тап «карта +» → `Картой *5953` / `*8782` + NewCardForm | **PASS** |

## Notes

- Live one-click 3₽ → «Ошибка оплаты, попробуйте снова» (банк; не mixed expanded).
- Expanded cards появились **только** после тапа «карта +».
- #46 (119 → CLIENT_ERROR) задеплоен тем же релизом; отдельный live CTA checkout не гоняли в этом прогоне.
