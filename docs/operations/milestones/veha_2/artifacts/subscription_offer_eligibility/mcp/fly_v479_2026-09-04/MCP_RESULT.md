# MCP RESULT — #77 Subscription offer eligibility

**Дата:** 2026-09-04  
**Fly:** **v479** · Point A  
**Guest:** `da143c8c-2043-436f-9631-d2fc0febfd07` (minted; не профиль Арама)

## Вердикт слота: **PASS** (A+B+C+D+E+F)

| Step | Result | Evidence |
|------|--------|----------|
| A UK settings | **PASS** | `/subscription_offer_setting/edit` → enabled, mode=subscription, min=1, signals=1 |
| B profile false | **PASS** | new guest `eligible_for_subscription_offer=false` |
| C engagement | **PASS** | `email_collected_at` set |
| D eligible true | **PASS** | after issued order → `eligible_for_subscription_offer=true` |
| E ready CTA | **PASS** | order `#202609-0013` ready → CTA **«Оформить подписку»** |
| F fallback | **PASS** | offer disabled → **«Оставить чаевые»** |

JSON: `mcp_result.json` · screenshot: `01_ready_subscription_cta.png`

После F настройки оффера на Point A **восстановлены** (enabled + subscription).
