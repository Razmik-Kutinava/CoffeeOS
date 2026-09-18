# MCP Result — Fly v499 post-deploy (TASK_93-L smoke)

**Дата:** 2026-09-18 · **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Fly:** v499 · image `deployment-01M2T582RETP2608KZMBMXAE1A`  
**Deploy Actions:** success `35340979415`  
**Git tip (develop):** `c0c9b7a7` / code `ead5cf38`

## Pre-deploy blockers (fixed this step)

| # | Issue | Fix |
|---|--------|-----|
| 1 | `release_command` → Rack::Attack requires Redis | Upstash `coffeeos-rack-attack` (ams, payg, eviction) · secret `RACK_ATTACK_REDIS_URL` |
| 2 | Attempt 2 → `ConcurrentMigrationError` | lock cleared (no advisory holders) · retry |

## Pack приёмки

| Gate | Result | Evidence |
|------|--------|----------|
| HTTP `/up` | **PASS** 200 | curl |
| Shop Point A HTML | **PASS** 200 | curl + browser |
| `/shop/api/categories` Point A | **PASS** 200 | curl · logs Completed 200 |
| Browser catalog + cart | **PASS** | меню загружено · cart «Фильтр-кофе Бразилия ×2» · Итого 358₽ · CTA +358₽ |
| Sentry unresolved lastSeen:-24h | **PASS** 0 | MCP `search_issues` org `llc-manageengine` / `ruby` |
| Fly logs | **PASS** | no 5xx/Exception in post-deploy window; SolidQueue started |
| Neon advisory locks | **PASS** | empty at retry time |
| УК Point A лента | **SKIP** | no UK login this step |
| Deep TASK_93 A–K G5 matrix | **SKIP** | smoke only; full matrix = next |

## Safety

No OTP/PAN written to guest profile; no Redis URL/password in this artifact.

## Verdict

**SMOKE PASS** on Fly v499. Deep MCP matrix (pay/webhook/OTP/Redis throttle/worker cascade) — следующий шаг.
