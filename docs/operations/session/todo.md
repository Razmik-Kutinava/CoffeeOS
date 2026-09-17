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
