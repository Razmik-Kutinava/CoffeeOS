# MCP #38 PKCS7 recheck · Fly v493 · 2026-09-08

| Поле | Значение |
|------|----------|
| Режим | **A simulate** (`WALLET_SIMULATE=1`) |
| Вердикт | **PASS** (PKCS7 slice simulate) |
| Prod certs | не выставляли — ZIP B не live |

## Preflight
- P0–P2 PASS · v493
- P3 `Config.simulate?=true` · `available?=true`

## B — wallet_pass
| # | Result |
|---|--------|
| B1 | **PASS** 200 · `application/vnd.apple.pkpass` · body 54 |
| B3a | **PASS** `PKPASS_STUB:379472aa-…:ready` |
| B3b/B | SKIP — нет prod certs (ожидаемо) |

Prod signing live — backlog secrets PEM.
