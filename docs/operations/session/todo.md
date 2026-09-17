# todo — #92 TASK_90: WebPush recovery after denied

| Поле | Значение |
|------|----------|
| **ID** | CBR **#92** (Google: TASK_90) |
| **Тип** | SBR · EXT #81 — recovery UI + deep-link/fallback `denied → settings` |
| **Статус** | **REVIEW** 2026-09-17 · push/CI · G5 Fly после deploy |
| **GREEN** | `0b7f0b2d` · Entire `01M2Q1AF4E2PWDD5JW1FZPRPF1` |
| **FIX** | `72dcb5e9` — Android intent always shows fallback (bugbot medium) |
| **RED** | `95a9a000` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md`](../milestones/veha_2/requirements/customer_tasks/TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md) |
| **Google** | https://docs.google.com/document/d/1YtZzj-Lf2HHrM4azejIuZISTKsWdu8q6y-kPHvm_d44/edit?usp=drivesdk |
| **Артефакты** | [`webpush_recovery_after_denied/`](../milestones/veha_2/artifacts/webpush_recovery_after_denied/) |
| **GATES** | [`GATES.md`](GATES.md) — G1–G4 met · G5 Fly pending |
| **OUT** | #81 остальные gaps (фоновые FCM/Wallet, чат) · iOS/Wallet · backend push · SW · #83/#84 · OrderStatus.svelte · orderStatusCtaMachine |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `95a9a000`
- [x] PHASE 2 GREEN — `0b7f0b2d`
- [x] PHASE 3 `/review` — bugbot+security · Entire · push/CI · G5 Fly после deploy

## Next

Deploy — только по апруву · затем Fly MCP Point A Android+Chrome (G5).

## DoD

1. После `denied` — recovery UI: объяснение + **«Открыть настройки»** + **«Смотреть готовность»**.
2. Deep-link в настройки сайта где возможно; иначе fallback-инструкция (не тупик).
3. Android + Chrome — обязательный acceptance.
4. «Смотреть готовность» → существующая статусная модель (**без** нового recovery-state / state machine).
5. После разрешения — штатный WebPush flow; без нового backend.

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/lib/orderStatusNotifyActions.js` | `openNotificationSettings` + fallback; Android intent + always fallback |
| `app/frontend/components/ActiveOrdersAccordion.svelte` | Recovery UI CTAs |
| `test/javascript/order_status_push_subscribe_test.mjs` | recovery + fallback tests |
| `test/javascript/active_orders_accordion_test.mjs` | structural recovery |
| `app/frontend/lib/firebasePush.js` | не трогали |

## Не ломать

1. Card / Rebill / Charge / SBP / one-click оплата и CTA «+сумма».
2. #83 dismiss (×) и #84 receipt / «Состав заказа».
3. iOS Apple Wallet · `OrderStatus.svelte` · `orderStatusCtaMachine.js`.
4. Backend `/shop/api/push/register` · VAPID/FCM · SW.

## Проверка

```bash
node --test test/javascript/order_status_push_subscribe_test.mjs test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs test/javascript/active_orders_accordion_test.mjs
ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
```
