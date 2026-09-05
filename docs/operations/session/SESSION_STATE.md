# SESSION_STATE

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-05 (promo amount from config SPEC)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| SPEC Задача-2 в todo.md | `/sbr` RED |
| Хардкод `GrowthPromo::AMOUNT_RUB=11` | читать `config["promo_amount_rub"]` |
| subscription rollback | **parked** (Point A offer still on) |

**last_done:** SPEC: промо-цена из `point_campaign_settings` (пути + Не ломать + Проверка)  
**next_step:** `/sbr` RED — тесты GrowthPromo + UserCardsController

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
