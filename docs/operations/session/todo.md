# todo — #82 Патч_1: каскад Presence grace + SMS short link

| Поле | Значение |
|------|----------|
| **ID** | CBR **#82** / каскад #39 · **Патч_1** 2026-09-17 |
| **Тип** | **ПАТЧ** · канон `TASK_PATCH.md` |
| **Статус** | **REVIEW** · CI green `35234267606` · Next: deploy апрув |
| **RED** | `33e7524c` |
| **GREEN** | `9b087faf` |
| **FIX** | `3f6ac720` (short-link session bind) |
| **Entire** | `01M2QWCCYY5P9QNJBJFBJSS6DK` на `3f6ac720` |
| **Ветка** | `develop` |
| **Канон** | `@coffeeos-task-patch` · `@spec-build-review` · `@coffeeos-commit-ops` |
| **ТЗ** | Google Doc § **Патч 1: 17.09.2026** · «Исправленный сценарий» |
| **Google** | https://docs.google.com/document/d/134SH9AGyliv3IxhXJiXz0jZxZo6HI27nJiOeN-zaNdU/edit?usp=drivesdk |
| **Артефакты** | [`order_ready_cascade_sms_status_sheet_fix/`](../milestones/veha_2/artifacts/order_ready_cascade_sms_status_sheet_fix/) |
| **OUT** | OrderStatusSheet / status UI · sync SMS · замена free channels · Telegram · Subtask 3.2 |

## SBR

- [x] `/patch` — секция Патч_1 + этот todo (Шаг 5)
- [x] PHASE 2 RED — `33e7524c`
- [x] PHASE 2 GREEN — Presence grace + SMS short link + `/o/:hash`
- [x] PHASE 3 `/review` — bugbot + security · Entire · push

## Файлы (ожидаемо)

- `app/services/shop/order_ready_presence.rb` — SMS grace
- `app/services/shop/guest_order_broadcaster.rb` — `begin_sms_grace!`
- `app/jobs/shop/order_ready_cascade_job.rb` — Presence retry
- `app/services/shop/order_ready_paid_notifier.rb` — short link SMS
- `app/services/shop/order_ready_sms_link.rb` — hash
- `app/controllers/shop/order_short_links_controller.rb` — `/o/:hash` + bind
- `config/routes.rb` — маршрут
- tests — cascade / presence / notifier / sms_link / short_links / channel

## Не ломать

- COMPONENT_MAP: OrderStatusSheet / ActiveOrdersAccordion / status UI
- GuestOrderBroadcaster: free channels WS→WebPush→Wallet
- GuestOrderChannel: presence вне grace
- SMS только cascade fallback; 3.2 network fail без регрессии

## Проверка

- zone tests → **36/0 PASS** (после review fix)

## DoD (Патч_1)

1. [x] Cable reconnect в grace ≠ SMS skipped
2. [x] Presence fail → retry
3. [x] SMS short link ≤70
4. [x] `/o/:hash` bind session + reconnect_token (bugbot fix)
5. [x] 3.2 без регрессии
6. [x] free channels не заменены

## Исправленный сценарий (чекбокс)

- [x] Subtask 2.1 (patch v2) — Presence grace
- [x] Subtask 2.1 (patch v2) — Presence retry
- [x] Subtask 3.1 (patch v2) — short link
- [x] Subtask 3.1 (patch v2) — ≤70
- [x] Subtask 3.2 — без изменений

## Next

deploy апрув → Fly MCP
