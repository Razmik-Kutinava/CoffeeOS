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
- [x] Flaky `events_controller_test.rb:208` — V2-T8 *(2026-05-30: 200 s + travel_to)*

---

## Прогон 10 — итог приёмки В2 (2026-06-02)

**Severity:** 🟢 (QA scope закрыт на Fly; веха §I ещё открыта)  
**Статус:** prog10 blocks **0–14** docs **done**; §I / живое демо / §E — **не закрыты**

### Что проверили

| Область | Результат | Артефакт |
|---------|-----------|----------|
| 3 org × 9 точек | PASS | [`PROG10_TENANTS.md`](PROG10_TENANTS.md) |
| curl shop + kiosk 9× | PASS | `prog10/_index/prog10_final_block13.json` |
| stress 8+8 | PASS | final + `prog10/smoke/prog10_stress_wave2.json` |
| RBAC / staff | PASS | `prog10/staff-rbac/prog10_rbac_matrix.md`, `prog10/staff-rbac/prog10_staff_isolation.json` |
| Kiosk → barista | PASS | `prog10_kiosk_barista*.json` |
| Витрина 5 точек | PASS | `prog10_shop_vitrina_*` |
| Связность CON-02…06 | PASS | `prog10/_index/prog10_connectivity.json` |
| Склад barista↔цех | PASS (модель 1 цех = 1 tenant) | `prog10/warehouse/prog10_warehouse_block12.json` |
| Kiosk GUC (CR-05) | PASS | `prog10/kiosk/prog10_kiosk_auth_fly_cr05.json` |

Индекс: [`artifacts/prog10/_index/prog10_final_index.json`](artifacts/prog10/_index/prog10_final_index.json).

### Что чинили в прогоне (код)

| Проблема | Fix | Коммиты / заметка |
|----------|-----|-------------------|
| Kiosk `KioskSetting` без tenant GUC | `SET LOCAL` в `kiosk/api/auth` | CR-05, тесты 7/0 |
| CacheCounter in-process | **wontfix** на Fly 1 pod | CR-04; при 2+ серверах → Redis |
| Deploy без flyctl в агенте | push `develop` + deploy владельцем | `fly deploy` после login |

### Что не делали (осознанный SKIP / backlog)

| Хвост | Куда |
|-------|------|
| `source=kiosk` в заказах | **V2-P10-08** — код после блоков 1–14 |
| Общий цех на N точек | **V2-BACKLOG-PREP-MULTI** → Веха 3 |
| API key в meta витрины | **SEC-07** — после В2 |
| Поддомены `{slug}.домен` | §I, свой домен |
| Живое демо, §E фидбек | §I блокеры |
| Flutter киоск UI | В3 |
| Refund Т-Банк | В3 |

### Lessons learned

1. **WSL для curl**, не `wsl` внутри WSL — одна команда без вложенного `wsl bash -lc`.
2. **ORDER_DELAY_SEC=5–7** на Fly — меньше rate-limit на checkout.
3. **Prep kitchen ≠ sales point** — e2e «точка → общий цех» не в scope В2; не путать с CON-06 RLS.
4. **Postmortem по блокам** — закрывать ops сразу (CHECKLIST + артефакт), §I отдельно после фидбека.

### Action items (после прогона 10)

- [x] Блоки 0–14 CHECKLIST + QA журнал
- [ ] §E [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) — фидбек заказчика
- [ ] §I — живое демо + апрув «веха 2 закрыта»
- [ ] V2-P10-08 `source=kiosk` — отдельный PR
- [ ] SEC-07 — убрать/ротировать ключ из meta (prod)

**Вердикт прогона 10:** **PASS** (QA на `coffeeos.fly.dev`). **Веха 2 официально не закрыта** до §E + §I.
