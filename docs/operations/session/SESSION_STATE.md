# SESSION_STATE

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-05 (intake #78 subscription billing)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| #78 intake `[x]` | `/spec` |
| subscription offer Point A | **OFF** |
| Задача-2 promo | parked (SPEC done, RED pending) |

**last_done:** docs intake #78 Архитектура подписки  
**next_step:** `/spec` — 2–7 путей + Не ломать + Проверка

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
| Point A restore | promo on · sub offer **OFF** (2026-09-05 rollback) |

**Fly logs:** shop API 200; StuckPayments spam source cleared · **Fly MCP:** PASS

**ctx_trim:** `2026-09-02`
