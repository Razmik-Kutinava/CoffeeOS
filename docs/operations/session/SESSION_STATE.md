# SESSION_STATE

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-05 (promo amount GREEN)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| Задача-2 GREEN `[x]` | `/regress` |
| Entire `01M1R4VQH6TPMM6SQ2RZ5JTM46` на `34a899d4` | `/review` |
| #78 SPEC в git | не в этом todo |

**last_done:** GREEN promo_amount_rub из `point_campaign_settings`  
**next_step:** `/regress` — growth + qa_section_2_3 + order_creator

### Ops: stuck T-Bank pending (2026-09-04)

| Что | Результат |
|-----|-----------|
| Cutoff `< 2026-09-01` | failed **186** · cancelled orders **182** · left **0** |
| By month | May 9 · Jun 155 · Jul 8 · Aug 14 |
| MCP leftovers today (Point A) | failed **2** · cancelled **2** |
| `STUCK_ALERT_CANDIDATES_NOW` | **0** |
| Script | `tmp/cleanup_stuck_tbank_payments.rb` (one-shot Fly runner) |

### Deploy + MCP (2026-09-04)

| Что | Статус |
|-----|--------|
| `fly deploy` | **v479** |
| #76 / #75 / #77 | PASS (live charge SKIP) |
| Point A restore | promo on · sub offer **OFF** · REVIEW bugbot/security clean |

**Fly logs:** shop API 200; StuckPayments spam source cleared · **Fly MCP:** PASS

**ctx_trim:** `2026-09-02`
