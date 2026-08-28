# Fly v464 MCP Point A — block cash shop API + ops push

**Дата:** 2026-08-28  
**Fly deploy:** **v464** · `deployment-01M143HBYRQB50Y04HZA1RVAZZ` · HEAD `20518d1f`  
**Примечание:** v463 failed (rolling retry) → v464 complete

## Вердикт: **PASS** (P0–P7)

| # | Check | Result |
|---|-------|--------|
| P0 | `/up` | **PASS** 200 |
| P1 | Point A shop | **PASS** |
| P2 | release v464 | **PASS** |
| P3 | `SHOP_SIMULATE_PAYMENT=0` | **PASS** |
| P4 | webhook invalid Token | **PASS** 401 |
| P5 | shop cash → 422 | **PASS** `cash payment not available online` |
| P6 | card → `pending_payment` + payment_url | **PASS** |
| P7 | `/payment/fail` без ownership | **PASS** 302 |

## Пачка приёмки

| Где | Result |
|-----|--------|
| Fly logs | **OK** — shop 200, 5xx/Exception не найдено в срезе |
| Sentry 24h | skip — не подключали в этом шаге |
| Neon / УК | skip — вне автоматизации |

## Артефакты

- `mcp_result.json`
- `bin/acceptance/fly_v461_mcp_acceptance.rb`
