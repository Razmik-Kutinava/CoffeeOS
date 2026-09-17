# todo — #92 TASK_90: WebPush recovery after denied

| Поле | Значение |
|------|----------|
| **ID** | CBR **#92** (Google: TASK_90) |
| **Тип** | SBR · EXT #81 — recovery UI + deep-link/fallback `denied → settings` |
| **Статус** | **intake** 2026-09-17 · ждёт `/spec` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md`](../milestones/veha_2/requirements/customer_tasks/TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md) |
| **Google** | https://docs.google.com/document/d/1YtZzj-Lf2HHrM4azejIuZISTKsWdu8q6y-kPHvm_d44/edit?usp=drivesdk |
| **Артефакты** | [`webpush_recovery_after_denied/`](../milestones/veha_2/artifacts/webpush_recovery_after_denied/) |
| **GATES** | [`GATES.md`](GATES.md) — G1–G4 baseline · G5 Fly pending |
| **OUT** | #81 остальные gaps (фоновые FCM/Wallet, чат) · iOS/Wallet · backend push · SW · #83/#84 · OrderStatus.svelte standalone |

## SBR

- [x] PHASE 0 intake
- [ ] PHASE 1 `/spec`
- [ ] PHASE 2 RED / GREEN
- [ ] PHASE 3 `/review`

## Next

`/spec`

## DoD (из ТЗ, кратко)

1. После `denied` — recovery UI: объяснение + «Открыть настройки» + «Смотреть готовность».
2. Deep-link в настройки сайта где возможно; иначе fallback-инструкция.
3. Android + Chrome — обязательный acceptance.
4. «Смотреть готовность» → существующая статусная модель (без нового recovery-state).
5. После разрешения — штатный WebPush flow; без нового backend.

## Проверка

```bash
node --test test/javascript/order_status_push_subscribe_test.mjs
node --test test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs
node --test test/javascript/active_orders_accordion_test.mjs
ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
```

**После GREEN / Review:** Fly MCP Point A Android+Chrome — denied → recovery → settings/fallback → return → status model. Артефакт в `artifacts/webpush_recovery_after_denied/mcp/`.

**Unlazy:** `node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/session/GATES.md`

## Next

`/spec`
