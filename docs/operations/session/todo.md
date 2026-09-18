# todo — #93 TASK_93-A: Деньги ↔ заказ (склад + webhook)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-A** |
| **Тип** | SBR · hot-path оплата / склад |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) § Блок A |
| **GATES** | [`session/GATES.md`](GATES.md) · [`artifacts/…/GATES.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES.md) |
| **Цель** | Банк CONFIRMED → всегда `payment.succeeded` + `order.accepted`; склад **не** откатывает оплату (R1–R7) |
| **OUT** | блоки B–L · deploy (L) · ослабление Amount check |

## SBR

- [x] PHASE 0 `/start` — intake `348f0b1a`
- [x] `/unlazy` — GATES A `630d744a` (G1–G3 unmet · G4→L)
- [x] PHASE 1 `/spec` — этот todo
- [ ] PHASE 2 RED — T-A1a…T-A6b падают · коммит `[RED]`
- [ ] PHASE 2 GREEN — политика soft-fail + audit · коммит `[GREEN]` · все T-A* PASS
- [ ] `/regress` — G2 zone payments/callbacks/jobs
- [ ] PHASE 3 `/review` — таблица A1–A6 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/services/callbacks/payment_status_updater.rb` — A1/A6: deduct вне rollback txn оплаты; cancelled/closed + succeeded → audit/`needs_refund`
- `app/services/inventory/order_recipe_deduction.rb` — A2: нет `find_or_create(qty:0)`→Error; missing/insufficient → skip + report
- `app/services/barista/order_creation_service.rb` — A3: та же политика, что updater (заказ accepted, склад алертом)
- `app/services/shop/order_creator.rb` — A3: то же при `order_status: accepted`
- `app/services/payments/tbank_adapter.rb` — A4: blank Amount → mismatch/`false` + видимость report
- `app/services/payments/tbank_payment_sync.rb` — A4: GetState blank/mismatch → `Rails.error.report` / audit (статус платежа не ослаблять)

### Blast-radius (+соседи)

- `test/integration/block_f_stock_flow_test.rb` — переписать hard-fail→422 под R5 (согласовать с A3)
- `test/jobs/payments/tbank_callback_job_test.rb` / `test/controllers/callbacks/tbank_controller_test.rb` — A5 CONFIRMED×stock; не трогать Init/subscription без нужды

## Матрица приёмки (RED → GREEN)

| ID | Тест | Файл |
|----|------|------|
| T-A1a | succeeded + insufficient stock → succeeded/accepted, stock не минус, audit | `payment_status_updater_test` |
| T-A1b | succeeded + stock row missing → no qty=0 trap, accepted + audit | ↑ |
| T-A2a | skip deduct + report when stock absent | `order_recipe_deduction_test` |
| T-A2b | insufficient → no deduct + signal | ↑ |
| T-A2c | sufficient → deduct (регрессия) | ↑ |
| T-A3a | barista create + bad stock → accepted + alert | `order_creation_service_test` |
| T-A3b | OrderCreator accepted + bad stock → no 500/rollback | `order_creator_test` / `block_f_stock_flow_test` |
| T-A4a | blank Amount → `notification_amount_matches?` false | `tbank_adapter_test` |
| T-A4b | blank/mismatch → report/audit ≥1; платёж не succeeded | adapter/sync/callback_job |
| T-A5a/b/c | CONFIRMED × missing / insufficient / enough stock | integration или controller/job |
| T-A6a/b | succeeded on cancelled/closed → audit (не quiet) | `payment_status_updater_test` |

## Не ломать

1. Happy path: CONFIRMED → succeeded + accepted + **deduct при достаточном стоке**
2. Amount mismatch по-прежнему **не** подтверждает платёж
3. Subscription intent (#78) — closed + fulfill, **не** barista accepted
4. Failed/REJECTED → cancel + journal как сейчас

## Проверка

```bash
# G1 — матрица A (+ новые A5/A6 файлы после RED)
bin/rails test test/services/callbacks/payment_status_updater_test.rb \
  test/services/inventory/order_recipe_deduction_test.rb \
  test/jobs/payments/tbank_callback_job_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/block_f_stock_flow_test.rb

# G2 — регресс зоны после GREEN (/regress)
bin/rails test test/services/payments/ test/services/callbacks/ test/jobs/payments/
```

Доп. A4: `bin/rails test test/services/payments/tbank_adapter_test.rb test/services/payments/tbank_payment_sync_test.rb`

## DoD блока A

- [ ] T-A1a…T-A6b (+ T-A5*) зелёные
- [ ] updater: deduction **не** откатывает `with_lock` txn оплаты
- [ ] нет `find_or_create(qty:0)`→Error на точках без склада
- [ ] barista / OrderCreator / updater — одна политика
- [ ] blank Amount / mismatch — report/audit
- [ ] cancelled/closed + succeeded — не quiet
- [ ] `/regress` G2 PASS · GATES G1–G3 met · G4 abandoned (L)
- [ ] REVIEW: таблица A1–A6 \| PASS · **без deploy**

## Next

`/sbr` RED — только падающие T-A*
