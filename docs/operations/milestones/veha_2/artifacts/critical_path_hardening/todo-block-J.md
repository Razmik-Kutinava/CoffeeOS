# todo — #93 TASK_93-J: Push / уведомления / worker

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-J** |
| **Тип** | SBR · hot-path shop status / push / queue |
| **Статус** | **regress PASS** · Next: `/review` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата J1–J4 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта J |
| **GATES** | [`GATES-block-J.md`](GATES-block-J.md) · session `todo.md` — живой канон |
| **Цель** | Status/webhook не ждут APNs/FCM; FCM OAuth cache + dead tokens; cascade wait GRACE+5s; Solid Queue runbook |
| **OUT** | WebPush UI (#90) · SMS текст (C) · Redis (I) · склад (A) · Fly worker process (L) |
| **Зависимость** | A затем J; после F удобно |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1** | Cable sync; PassUpdater/APNs/FCM — async only; broadcaster ≠ sync PassUpdater |
| **R1b** | Новый `Shop::AppleWallet::PassUpdateJob.perform_later` |
| **R2** | `GuestOrderBroadcaster` после `payment.with_lock` |
| **R3** | ReadyPush `perform_now` FCM ок (job уже async) |
| **R4** | `Rails.cache.fetch("fcm:oauth:…", expires_in: 50.minutes)` |
| **R5** | UNREGISTERED / INVALID_ARGUMENT token → clear push_token + push_enabled false |
| **R6** | `SMS_GRACE=15s` · `SMS_GRACE_JOB_BUFFER=5s` · wait=**20s** |
| **R7** | `docs/operations/runbooks/SOLID_QUEUE_FLY.md` |
| **R8** | Puma plugin contract; cascade/ready = perform_later only; tbank perform_now primary |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES J
- [x] PHASE 1 `/spec` — зеркало session `todo.md`
- [x] PHASE 2 RED — T-J1a · T-J2a · T-J3a · `[RED]` `06979f96`
- [x] PHASE 2 GREEN — R1–R8 · `[GREEN]`
- [x] `/regress` — G4 · **87/0** (2026-09-18)
- [ ] PHASE 3 `/review` — J1–J4 PASS · push · без deploy

## Файлы (ожидаемо)

- `app/services/shop/guest_order_broadcaster.rb`
- `app/services/callbacks/payment_status_updater.rb`
- `app/services/shop/fcm_client.rb`
- `app/jobs/shop/order_ready_cascade_job.rb`
- `app/jobs/shop/apple_wallet/pass_update_job.rb` (новый)
- `docs/operations/runbooks/SOLID_QUEUE_FLY.md` (новый)
- `test/services/shop/guest_order_broadcaster_test.rb`

## Не ломать / Проверка

См. канон в `docs/operations/session/todo.md` (тот же текст секций).
