# MCP #80 — Fly v492 — Slice V live — 2026-09-08

Point A · tip `46f55bd2` (+ restore todo) · **v492** `deployment-01M20HDZR4PW3H193890PGVZ2J`

| Step | Result | Notes |
|------|--------|-------|
| **V0** preconditions | **PASS** | `/shop?tenant_id=2fdee1ac-…` 200 · checkout → «Вход по телефону» · `SHOP_OTP_LOG_FALLBACK=false` (fly ssh) |
| **V1** init Callcheck | **BLOCKED** | нет телефона владельца/агента в сессии — `init_callcheck` не вызывали |
| **V2** live call → `check_status` confirmed | **BLOCKED** | зависит от V1 |
| **V3** leave wizard / session | **BLOCKED** | зависит от V2 |

**Screens:** `01_phone_input_v0.png` (wizard phone step)

**Код:** не трогали (verify-first · нет FAIL)

**Fly MCP:** **BLOCKED** — не PASS, не FAIL. Риск «leave wizard после звонка» **не снят**.

## Вердикт

| | |
|---|---|
| Slice V | **BLOCKED** |
| Slice F | **не делать** (нет FAIL) |
| Дальше | дать `+79…` владельца → повторить `/sbr` Slice V |

## Не путать

- UI path до ввода телефона ≠ live Callcheck PASS  
- v486 SKIP / v492 BLOCKED — один класс: нет звонка владельца
