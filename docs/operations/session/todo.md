# todo — block cash on public shop API (REVIEW)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 3 REVIEW local+subagents | push ops отложен (Entire gap HEAD) | deploy по апруву; Entire backfill |

**GREEN:** `1220d3e2` · **Fly v461:** cash 422 PASS

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** `1220d3e2` |
| /sbr verify | **`[x]`** 46/0 |
| /regress | **`[x]`** 113/0 |
| REVIEW | **`[x]`** bugbot+security PASS; Entire gap на HEAD |
| push | **`[ ]`** — Entire `explain HEAD` пустой |
| deploy | **`[ ]`** — апрув |

## Проверка

Regress: **113 runs, 417 assertions, 0 failures, 2 skips** (2026-08-28)

## Не ломать

- Barista POS cash + CashShift
- Shop card/sbp + T-Bank callback
