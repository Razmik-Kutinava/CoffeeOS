# todo — #93 TASK_93-A: Деньги ↔ заказ (склад + webhook)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-A** |
| **Тип** | SBR · hot-path оплата / склад |
| **Статус** | **GREEN** · Next: `/regress` |
| **RED** | `fc97a432` |
| **GREEN** | `bba068f9` |
| **Entire** | `01M2SSQXT1V67AK260SH1P9RAX` (attach session; trailer race на чужой HEAD) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) § Блок A |
| **GATES** | [`GATES-block-A.md`](GATES-block-A.md) |
| **Цель** | Банк CONFIRMED → всегда `payment.succeeded` + `order.accepted`; склад **не** откатывает оплату |

## SBR

- [x] PHASE 0 `/start` — intake
- [x] `/unlazy` — GATES-block-A
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `fc97a432`
- [x] PHASE 2 GREEN — `bba068f9` · Local 83 PASS
- [ ] `/regress` — G2 zone payments/callbacks/jobs
- [ ] PHASE 3 `/review` — таблица A1–A6 PASS · push · **без deploy**

## Проверка

```bash
bin/rails test test/services/callbacks/payment_status_updater_test.rb \
  test/services/inventory/order_recipe_deduction_test.rb \
  test/jobs/payments/tbank_callback_job_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/block_f_stock_flow_test.rb

bin/rails test test/services/payments/ test/services/callbacks/ test/jobs/payments/
```

## Next

`/regress`
