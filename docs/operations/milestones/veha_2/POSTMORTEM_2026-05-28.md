# Postmortem — Fly worker + T-Bank callback (2026-05-28)

**Дата:** 2026-05-28  
**Severity:** 🟡 (prod worker down, оплата через perform_now fallback)  
**Статус:** resolved

---

## Что случилось

1. **Worker crash loop** — `bin/jobs` на Fly exit code 1: «Solid Queue … pool is 3, need 5 threads». Worker machine stopped → async jobs не обрабатывались.
2. **Live-табло барista** — broadcast через async job не доходил без F5 (worker мёртв).
3. **Callback прогон 3** — `TbankCallbackJob` шёл через `perform_now` fallback (queue недоступен / worker down).
4. **Host authorization** — smoke callback на `127.0.0.1` → HTTP 403 до исключения `/callbacks/*`.

---

## Root cause

- `RAILS_MAX_THREADS=3` → `database.yml` pool=3, Solid Queue worker требует ≥5 connections.
- Worker process без http_service — падал и не перезапускался стабильно до fix pool.

---

## Fix

| # | Изменение | Commit |
|---|-----------|--------|
| 1 | Sync `Barista::OrderBoardBroadcaster` из cash/callback | `0bde33d` |
| 2 | `DB_POOL=8` в `fly.toml` + `database.yml` | `750490e` |
| 3 | `/callbacks/*` exclude from `host_authorization` | `750490e` |
| 4 | `fly:callback_smoke` rake для signed E2E | `750490e` |
| 5 | Worker path PASS: order `85bef120`, `TbankCallbackJob` on worker | prod 2026-05-28 |

---

## Prevention

- CI: `fly scale count web=1 worker=1` после deploy.
- Перед prod: `fly logs` — нет «Exiting» на worker; `bin/rake fly:callback_smoke`.
- Док: [`PAYMENT.md`](PAYMENT.md) прогон 4, [`ISSUES.md`](../../ISSUES.md).

---

## Action items

- [x] DB pool fix deployed
- [x] Signed callback via worker verified
- [x] UX таймаут БД >5с — прогон 8 PASS (`slow_request_ux_test.rb`)
- [ ] Flaky `events_controller_test.rb:208` — V2-T8
