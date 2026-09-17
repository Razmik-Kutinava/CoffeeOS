# todo — #82 Патч_1: каскад Presence grace + SMS short link

| Поле | Значение |
|------|----------|
| **ID** | CBR **#82** / каскад #39 · **Патч_1** 2026-09-17 |
| **Тип** | **ПАТЧ** · канон `TASK_PATCH.md` |
| **Статус** | **RED** · тесты написаны · ждут GREEN |
| **RED** | _(pending commit)_ |
| **Ветка** | `develop` |
| **Канон** | `@coffeeos-task-patch` · `@spec-build-review` · `@coffeeos-commit-ops` |
| **ТЗ** | Google Doc § **Патч 1: 17.09.2026** · «Исправленный сценарий» |
| **Google** | https://docs.google.com/document/d/134SH9AGyliv3IxhXJiXz0jZxZo6HI27nJiOeN-zaNdU/edit?usp=drivesdk |
| **Артефакты** | [`order_ready_cascade_sms_status_sheet_fix/`](../milestones/veha_2/artifacts/order_ready_cascade_sms_status_sheet_fix/) |
| **OUT** | OrderStatusSheet / status UI · sync SMS из update_status · замена WS/WebPush/Wallet на SMS · Telegram · Subtask 3.2 (уже ок) |

## SBR

- [x] `/patch` — секция Патч_1 + этот todo (Шаг 5)
- [x] PHASE 2 RED
- [ ] PHASE 2 GREEN
- [ ] PHASE 3 `/review`

## Файлы (ожидаемо)

- `app/services/shop/order_ready_presence.rb` — SMS grace: suppress `mark_online!` во время grace
- `app/services/shop/guest_order_broadcaster.rb` — `begin_sms_grace!` при enqueue cascade (граница SMS fallback only)
- `app/jobs/shop/order_ready_cascade_job.rb` — Presence fail → log + `retry_on`
- `app/services/shop/order_ready_paid_notifier.rb` — SMS текст `codeblack.xyz/o/{order_hash}`, ≤70
- `app/services/shop/order_ready_sms_link.rb` — короткий `order_hash` + resolve (NEW)
- `app/controllers/shop/order_short_links_controller.rb` — `GET /o/:order_hash` → shop `#/order/:id` (NEW)
- `config/routes.rb` — маршрут `/o/:order_hash`
- `test/jobs/shop/order_ready_cascade_job_test.rb` — grace reconnect / Presence retry / SMS text
- `test/services/shop/order_ready_presence_test.rb` — grace suppress online
- `test/services/shop/order_ready_paid_notifier_test.rb` — short link + ≤70
- `test/services/shop/order_ready_sms_link_test.rb` — hash roundtrip (NEW)
- `test/integration/shop/order_short_links_test.rb` — redirect (NEW)

## Не ломать

- COMPONENT_MAP: **OrderStatusSheet** / **ActiveOrdersAccordion** / status UI — не трогать
- **GuestOrderBroadcaster**: контракт бесплатных каналов WS → WebPush → Apple Wallet; только граница SMS grace/enqueue
- **GuestOrderChannel** / Cable: presence online вне grace; не ломать subscribe/unsubscribe
- SMS не синхронно из update_status; SMS только fallback после cascade
- Subtask 3.2: timeout/5xx → failed log, worker не падает

## Проверка

- `ruby bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/order_ready_presence_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/services/shop/order_ready_sms_link_test.rb test/integration/shop/order_short_links_test.rb test/channels/shop/guest_order_channel_test.rb`

## DoD (Патч_1)

1. [ ] Cable reconnect внутри SMS_GRACE ≠ ложный SMS skipped
2. [ ] Presence/cache error → log + ActiveJob retry (не silent swallow)
3. [ ] SMS через `SmsRuClient.send_message!` с `codeblack.xyz/o/{order_hash}`
4. [ ] SMS ≤70 до HTTP; >70 → ValidationError без HTTP
5. [ ] 3.2 network fail — без регрессии
6. [ ] Бесплатные WS/WebPush/Wallet не заменены SMS

## Исправленный сценарий (чекбокс)

- [ ] Subtask 2.1 (patch v2) — Presence после grace без ложного skip на reconnect
- [ ] Subtask 2.1 (patch v2) — Presence/cache unavailable → retry
- [ ] Subtask 3.1 (patch v2) — `send_message!` + short link вместо `#order_number`
- [ ] Subtask 3.1 (patch v2) — ≤70 до HTTP
- [x] Subtask 3.2 — без изменений (уже ок)

## Next

GREEN
