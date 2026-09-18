# todo — #93 TASK_93-C: SMS «заказ готов» + short link (канон)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-C** |
| **Статус** | **GREEN** · Next: `/regress` |
| **RED** | `1346d895` |
| **GREEN** | `c2ef2d68` (идентичный `fd57e777` в параллельной линии) |
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
- [x] GREEN `fd57e777` — 18/0 PASS
- [ ] `/regress`
- [ ] `/review`

## Проверка

```bash
bin/rails test test/services/shop/order_ready_sms_link_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/integration/shop/order_short_links_test.rb test/integration/rack_attack_order_short_link_test.rb
```
