# todo — Задача-1 Патч 1: 22.09.2026 · Экстренное отключение subscription-оффера

| Поле | Значение |
|------|----------|
| **ID** | Задача-1 · Патч 1 · 22.09.2026 |
| **Док** | [Задача-1 Экстренное отключение subscription-оффера на Point A.md](../milestones/veha_2/requirements/customer_tasks/Задача-1%20Экстренное%20отключение%20subscription-оффера%20на%20Point%20A.md) |
| **Google** | https://docs.google.com/document/d/1h-ChIiU09TKAIWsZDjbEWfOgEzZNhmUdwQghDqHI3CY/edit |
| **Статус** | GREEN · config Fly + verify |
| **Scope** | Только «Исправленный сценарий» Патча 1 (Subtask 2 / 3 / 5 patch v2) |

## SBR: GREEN done (config-only)

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
node --test test/javascript/order_status_cta_machine_test.mjs
# Fly: SubscriptionOfferSetting Point A → enabled=false, second_cta_mode=subscription
```

## DoD

- [x] Subtask 2 (patch v2): Point A `enabled=false`; tips не механизм disable
- [x] Subtask 3 (patch v2): других risky точек нет
- [x] Subtask 5 (patch v2): subscription CTA не показывается (matrix test)
- [x] Артефакт + DEMO_FEEDBACK
- [ ] Чек-лист повторного включения — только когда billing/экран готовы (не этот шаг)

## Subtasks (patch v2)

- [x] Subtask 2 (patch v2): Point A `enabled=false`
- [x] Subtask 3 (patch v2): другие точки `enabled=false` (n/a — нет)
- [x] Subtask 5 (patch v2): verify после отключения
