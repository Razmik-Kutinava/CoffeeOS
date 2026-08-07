# MCP Fly v441 — #33 El helpers re-check (2026-08-07)

**Release:** **v441** · deployment `01KZDZ59Z9113BYEWRVEHF3QBT`  
**Связка:** полный live S1/S2 уже PASS на **v440**; на v441 подтверждены bundle helpers.

## Verdict

| Check | Result |
|---|---|
| Deploy /up | **PASS** |
| `El()` decline → `showExpandedCards:!1` / `showNewCardForm:!1` | **PASS** (application-D-6WcAtM.js) |
| `Dl()` card+ → expanded+form | **PASS** |
| Live S1/S2 UI | покрыто v440 evidence; на v441 фокус #46 checkout |

**v440 evidence:** [`../fly_2026-08-07/`](../fly_2026-08-07/)
