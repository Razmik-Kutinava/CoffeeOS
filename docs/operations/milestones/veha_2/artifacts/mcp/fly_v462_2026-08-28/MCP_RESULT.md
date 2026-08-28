# Fly v462 MCP Point A — post rubocop deploy

**Дата:** 2026-08-28  
**Fly deploy:** **v462** · `deployment-01M13ZVNYK4Y3M75G9ZHN7RY2J` · HEAD `9f4f8ee0`  
**Delta vs v461:** rubocop-only (`9540afc0` style fix)

## Вердикт: **PASS** (hot-path P0–P7) · **PARTIAL** (полная приёмка стенда)

| # | Check | Result |
|---|-------|--------|
| P0 | `/up` | **PASS** 200 |
| P1 | Point A shop | **PASS** browser + HTTP |
| P2 | release v462 | **PASS** |
| P3 | `SHOP_SIMULATE_PAYMENT=0` | **PASS** |
| P4 | webhook invalid Token | **PASS** 401 |
| P5 | shop cash → 422 | **PASS** |
| P6 | card → `pending_payment` + payment_url | **PASS** |
| P7 | `/payment/fail` без ownership | **PASS** 302 |
| B2.1 | barista board | **PARTIAL** (`b21_cancel` marker) |

## Fly logs

Срез после deploy: shop 200 OK, **5xx/Exception не найдено**.

## Артефакты

- `mcp_result.json`
- `01_shop_point_a.png`
- `bin/acceptance/fly_v461_mcp_acceptance.rb` (повторный прогон)
