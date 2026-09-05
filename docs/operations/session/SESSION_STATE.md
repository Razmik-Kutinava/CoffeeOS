# SESSION_STATE

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-05 (sub-offer emergency rollback SPEC)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| Point A `subscription_offer` on (v479) | `/sbr` Audit SELECT → УК `enabled=false` |
| SPEC rollback | todo.md |
| Код CTA / eligibility | **не трогать** |

**last_done:** SPEC экстренного отката subscription-оффера  
**next_step:** `/sbr` — SELECT всех точек → откат Point A через УК

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
| Point A restore | promo on · sub offer on |

**Fly logs:** shop API 200; StuckPayments spam source cleared · **Fly MCP:** PASS

**ctx_trim:** `2026-09-02`
