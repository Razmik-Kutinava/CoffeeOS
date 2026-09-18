# todo — #93 TASK_93-C: SMS «заказ готов» + short link (канон)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-C** |
| **Статус** | **REVIEW** · push/CI · без deploy |
| **RED** | `1346d895` |
| **GREEN** | `c2ef2d68` |
| **Entire** | `01M2SSQXT1V67AK260SH1P9RAX` на `c2ef2d68` |
| **GATES** | [`GATES-block-C.md`](GATES-block-C.md) · G1–G5 met · G6→L |

## Канон

| ID | Решение |
|----|---------|
| **R2-A** | host = SHOP_SMS_LINK_HOST \|\| APP_HOST \|\| coffeeos.fly.dev |
| **TTL** | 48h · one-time SKIP |
| **Throttle** | 30/min/IP GET /o/ |

## SBR

- [x] `/start` · `/unlazy` · `/spec` · RED · GREEN · `/regress`
- [x] `/unlazy` approve+reverify — G1–G5 met · G6→L
- [x] `/review` — Local 18/0 · bugbot clean · security no medium+ · Entire · push

## REVIEW-таблица

```
C1 T-C1a T-C1b T-C1c     PASS
C2 T-C2b T-C2c           PASS (R2-A; T-C2a N/A)
C3 T-C3a..d              PASS
C4 T-C4a T-C4b           PASS
C5 T-C5a T-C5c           PASS (T-C5b SKIP)
```

## Проверка

```bash
bin/rails test test/services/shop/order_ready_sms_link_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/integration/shop/order_short_links_test.rb test/integration/rack_attack_order_short_link_test.rb
```
