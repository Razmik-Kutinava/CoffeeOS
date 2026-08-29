# Fly v465 MCP Point A — barista shift-scoped orders deploy

**Дата:** 2026-08-29  
**Fly deploy:** **v465** · `deployment-01M167Z816GPZYVX109PBWXQQD` · HEAD `4a416668`  
**Фича:** barista `show`/`update_status`/`cancel` — только текущая смена (+ витрина mobile)

## Вердикт: **PASS** (P0–P7)

| # | Check | Result |
|---|-------|--------|
| P0 | `/up` | **PASS** 200 |
| P1 | Point A shop | **PASS** |
| P2 | release v465 | **PASS** |
| P3 | `SHOP_SIMULATE_PAYMENT=0` | **PASS** |
| P4 | webhook invalid Token | **PASS** 401 |
| P5 | shop cash → 422 | **PASS** |
| P6 | card → `pending_payment` | **PASS** |
| P7 | `/payment/fail` без ownership | **PASS** 302 |
| — | `/barista` | **PASS** 302 → login |

## Пачка приёмки

| Где | Result |
|-----|--------|
| Fly logs | **OK** — boot seed шум + transient health; после Puma listen 0.0.0.0:3000 — health passing; 5xx/Exception в срезе нет |
| Sentry 24h | **чисто** — `is:unresolved lastSeen:-24h` → 0 (org llc-manageengine / ruby) |
| Neon / УК | skip — вне автоматизации |

## Артефакты

- `mcp_result.json`
- скрипт: `bin/acceptance/fly_v461_mcp_acceptance.rb`
