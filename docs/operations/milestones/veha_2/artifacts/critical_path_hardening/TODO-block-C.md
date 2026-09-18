# todo — #93 TASK_93-C: SMS «заказ готов» + short link (канон)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-C** |
| **Статус** | **REGRESS PASS** · Next: `/review` |
| **RED** | `1346d895` |
| **GREEN** | `c2ef2d68` |
| **GATES** | [`GATES-block-C.md`](GATES-block-C.md) |

## Канон

| ID | Решение |
|----|---------|
| **R2-A** | host = SHOP_SMS_LINK_HOST \|\| APP_HOST \|\| coffeeos.fly.dev |
| **TTL** | 48h от ready_notified_at ‖ ready_at ‖ updated_at |
| **Throttle** | 30/min/IP GET /o/ |
| **One-time** | SKIP |
| **SMS** | `CODE:BLACK. Готов! {host}/o/{hash}` ≤70 |

## SBR

- [x] `/start` · `/unlazy` · `/spec`
- [x] RED `1346d895`
- [x] GREEN `c2ef2d68` — 18/0 PASS
- [x] `/regress` — 18 runs / 0 failures (2026-09-18)
- [ ] `/review`

## Проверка

```bash
bin/rails test test/services/shop/order_ready_sms_link_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/integration/shop/order_short_links_test.rb test/integration/rack_attack_order_short_link_test.rb
```

**Local regress:** `18 runs, 108 assertions, 0 failures` · seed 61367
