# todo — #92 TASK_90: WebPush recovery after denied

| Поле | Значение |
|------|----------|
| **ID** | CBR **#92** (Google: TASK_90) |
| **Тип** | SBR · EXT #81 — recovery UI + deep-link/fallback `denied → settings` |
| **Статус** | **regress PASS** 2026-09-17 · ждёт `/review` |
| **GREEN** | `0b7f0b2d` · Entire `01M2Q1AF4E2PWDD5JW1FZPRPF1` |
| **RED** | `95a9a000` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md`](../milestones/veha_2/requirements/customer_tasks/TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md) |
| **Google** | https://docs.google.com/document/d/1YtZzj-Lf2HHrM4azejIuZISTKsWdu8q6y-kPHvm_d44/edit?usp=drivesdk |
| **Артефакты** | [`webpush_recovery_after_denied/`](../milestones/veha_2/artifacts/webpush_recovery_after_denied/) |
| **GATES** | [`GATES.md`](GATES.md) — G1–G4 baseline met · G5 Fly pending |
| **OUT** | #81 остальные gaps (фоновые FCM/Wallet, чат) · iOS/Wallet · backend push · SW · #83/#84 · OrderStatus.svelte · orderStatusCtaMachine |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec` — канон в этом todo
- [x] PHASE 2 RED — `95a9a000` recovery UI + fallback + dismiss
- [x] PHASE 2 GREEN — `0b7f0b2d` deep-link/fallback + CTA «Смотреть готовность»
- [ ] PHASE 3 `/review`

## Next

`/review`

## DoD

1. После `denied` — recovery UI: объяснение + **«Открыть настройки»** + **«Смотреть готовность»**.
2. Deep-link в настройки сайта где возможно; иначе fallback-инструкция (не тупик).
3. Android + Chrome — обязательный acceptance.
4. «Смотреть готовность» → существующая статусная модель (**без** нового recovery-state / state machine).
5. После разрешения — штатный WebPush flow; без нового backend.

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/lib/orderStatusNotifyActions.js` | Допилить `openNotificationSettings`: результат `opened`/`fallback`; текст инструкции; не ломать toast/CTA контракт |
| `app/frontend/components/ActiveOrdersAccordion.svelte` | Recovery UI после denied: «Открыть настройки» + «Смотреть готовность»; dismiss → обычный статус |
| `test/javascript/order_status_push_subscribe_test.mjs` | RED: recovery CTA/copy; fallback при `opened:false`; wire accordion |
| `test/javascript/active_orders_accordion_test.mjs` | RED/structural: кнопки recovery + dismiss без нового state machine |
| `app/frontend/lib/firebasePush.js` | Только если RED: корректный `permission` после возврата; **не** трогать register token / VAPID |

**Blast-radius (+соседи, только если RED покажет дыру):**

| Path | Почему |
|------|--------|
| `test/javascript/order_status_notify_actions_test.mjs` | Регресс публичных контрактов notify (уже в Проверка) |
| `app/frontend/components/OrderActionButtons.svelte` | Только если CTA push-label ломается от recovery UI |

## Не ломать

1. Card / Rebill / Charge / SBP / one-click оплата и CTA «+сумма».
2. #83 dismiss (×) и #84 receipt / «Состав заказа» — публичные контракты `openOrderReceipt` / `toggleExpandedOrder`.
3. iOS Apple Wallet · `OrderStatus.svelte` standalone push · `orderStatusCtaMachine.js`.
4. Backend `/shop/api/push/register` · VAPID/FCM config · PWA Service Worker.

## Проверка

```bash
node --test test/javascript/order_status_push_subscribe_test.mjs test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs test/javascript/active_orders_accordion_test.mjs
ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
```

**После GREEN / Review:** Fly MCP Point A Android+Chrome — denied → recovery → settings/fallback → return → status model. Артефакт в `artifacts/webpush_recovery_after_denied/mcp/`.

**Unlazy:** после GREEN `node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/session/GATES.md`
