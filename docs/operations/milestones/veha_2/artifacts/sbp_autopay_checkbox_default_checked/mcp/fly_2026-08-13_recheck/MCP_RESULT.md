# MCP Point A recheck — Fly v451/v452 (2026-08-13)

**Стенд:** Point A · commit `c17c67cd`  
**Deploy:** v451 (NET fix `7d4e9c2c`) · v452 (A6 `refresh_cache!` `c17c67cd`) · `/up` 200

| Check | Вердикт | Evidence |
|-------|---------|----------|
| NET CTA «Нет связи. Повторить» | **PASS** | offline pay |
| NET нет сырого `Failed to fetch` | **PASS** | alerts=[] |
| A6 cancel → `has_active_order=false` | **PASS** | API + UI без reload |
| A6 «повторить» ×3 после cancel | **PASS** | snapshot + screenshot |

**Note:** первый A6 на v451 FAIL из‑за race (poll frequent перезаписал SolidCache после delete-only bust). Закрыто `refresh_cache!` (bust+write) на v452.
