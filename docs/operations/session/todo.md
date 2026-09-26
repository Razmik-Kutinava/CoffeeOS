# todo — Задача-1 Патч 1: 22.09.2026 · Экстренное отключение subscription-оффера

| Поле | Значение |
|------|----------|
| **ID** | Задача-1 · Патч 1 · 22.09.2026 |
| **Док** | [Задача-1 Экстренное отключение subscription-оффера на Point A.md](../milestones/veha_2/requirements/customer_tasks/Задача-1%20Экстренное%20отключение%20subscription-оффера%20на%20Point%20A.md) |
| **Google** | https://docs.google.com/document/d/1h-ChIiU09TKAIWsZDjbEWfOgEzZNhmUdwQghDqHI3CY/edit |
| **Статус** | REVIEW done · CI green |
| **GREEN** | `61b3fc79` |
| **Entire** | `01M3F5K4DJJ5WE8P2755NHQ022` на `61b3fc79` |
| **CI** | [`36252477440`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36252477440) success (+ Semgrep + CodeQL) |
| **Scope** | Только «Исправленный сценарий» Патча 1 (Subtask 2 / 3 / 5 patch v2) |

## SBR: REVIEW done

## Файлы (ожидаемо)

- `subscription_offer_settings` (Fly Point A) — `enabled=false`; mode не tips-as-disable
- `docs/.../ops/rollback_point_a_patch_v2_2026-09-26.json` — audit + after
- `test/javascript/order_status_cta_machine_test.mjs` — verify no subscription CTA при enabled=false
- customer_tasks md — секция Патч 1 (галочки)
- `DEMO_FEEDBACK.md` — строка Патч v2

## Не ломать

- COMPONENT_MAP: `orderStatusCtaMachine` / `OrderActionButtons` / `OrderStatus` — **не менять** (общий с #77)
- `SubscriptionOfferEligibility` / сигналы вовлечённости / tips pending adapter
- backend billing / экран оформления / `INTEGRATIONS.md`

## Проверка

```bash
node --test test/javascript/order_status_cta_machine_test.mjs  # 18 PASS
# Fly: Point A enabled=false, second_cta_mode=subscription
```

## DoD

- [x] Subtask 2/3/5 patch v2
- [x] bugbot + security — clean
- [x] Entire `01M3F5K4DJJ5WE8P2755NHQ022` на `61b3fc79`
- [x] push develop
- [x] CI green [`36252477440`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36252477440) (+ Semgrep + CodeQL)
- [ ] Чек-лист повторного включения — когда billing/экран готовы
- [ ] deploy — не нужен (config уже на Fly)

## Subtasks (patch v2)

- [x] Subtask 2 (patch v2): Point A `enabled=false`
- [x] Subtask 3 (patch v2): другие точки (n/a)
- [x] Subtask 5 (patch v2): verify после отключения
