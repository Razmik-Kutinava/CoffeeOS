# Fly v461 MCP Point A — undeployed session commits

**Дата:** 2026-08-28  
**Fly deploy:** **v461** · `deployment-01M13YCKVJ4CDQBFQFKTHM1NZC` · HEAD `f5ce8118`  
**Push:** `3e476f66..f5ce8118` → `origin/develop`

## Коммиты в релизе (после v460)

| Hash | Суть |
|------|------|
| `bea1c226` | OTP codes убраны из Rails.logger |
| `4ad49718` | OTP tests + DEAD CODE clients |
| `5a061aa6` | fail-redirect ownership (reconnect_token gate) |
| `a0023a8a` | SHOP_SIMULATE_PAYMENT default 0 + prod guard |
| `1220d3e2` | block cash on public shop API |
| `f5ce8118` | ops HANDOFF |

## Вердикт: **PASS** (hot-path session commits)

| # | Check | Result | Notes |
|---|-------|--------|-------|
| P0 | `/up` | **PASS** | 200 |
| P1 | Point A shop | **PASS** | каталог + корзина; browser screenshot |
| P2 | release ≥ v461 | **PASS** | v461 |
| P3 | `SHOP_SIMULATE_PAYMENT` | **PASS** | `0` on web machine |
| P4 | webhook invalid Token | **PASS** | 401 `invalid token` |
| P5 | shop cash → 422 | **PASS** | `cash payment not available online` |
| P6 | card + simulate=0 | **PASS** | `pending_payment` + `payment_url` (не accepted) |
| P7 | `/payment/fail` без ownership | **PASS** | 302 → `#/payment-result?status=fail` |
| B2.1 barista board | **PARTIAL** | b21_cancel marker false (pre-existing UI copy) |

## Open (не блокирует v461)

- Live Init / fiscal notify (#72/#73) — как v460 PARTIAL
- B2.1 «СТОП! ЗАКАЗ ОТМЕНЁН» marker — косметика табло, не регресс v461

## Артефакты

- `mcp_result.json` — machine-readable
- `01_shop_point_a.png` — browser MCP (если сохранён)
- `bin/acceptance/fly_v461_mcp_acceptance.rb` — повторный прогон
