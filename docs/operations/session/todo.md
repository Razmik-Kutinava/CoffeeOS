# todo — #93 TASK_93-A: Деньги ↔ заказ (склад + webhook)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-A** |
| **Тип** | SBR · hot-path оплата / склад |
| **Статус** | **GREEN** · Next: `/regress` |
| **RED** | `fc97a432` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) § Блок A |
| **GATES** | [`GATES-block-A.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-A.md) (канон A; `session/GATES.md` может быть B/C) |
| **Цель** | Банк CONFIRMED → всегда `payment.succeeded` + `order.accepted`; склад **не** откатывает оплату (R1–R7) |
| **OUT** | блоки B–L · deploy (L) · ослабление Amount check |

## SBR

- [x] PHASE 0 `/start` — intake `348f0b1a`
- [x] `/unlazy` — GATES A `630d744a` (G1–G3 unmet · G4→L)
- [x] PHASE 1 `/spec` — todo A1–A6
- [x] PHASE 2 RED — T-A1a…T-A6b · `fc97a432`
- [x] PHASE 2 GREEN — soft-fail + audit · (этот коммит)
- [ ] `/regress` — G2 zone payments/callbacks/jobs
- [ ] PHASE 3 `/review` — таблица A1–A6 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/services/callbacks/payment_status_updater.rb` — A1/A6: deduct после txn; cancelled/closed + succeeded → audit
- `app/services/inventory/order_recipe_deduction.rb` — A2: skip + `inventory_deduction_skipped`
- `app/services/barista/order_creation_service.rb` — A3 soft-fail
- `app/services/shop/order_creator.rb` — A3 soft-fail
- `app/services/payments/tbank_adapter.rb` — A4 blank Amount false (уже)
- `app/services/payments/tbank_payment_sync.rb` — A4 `tbank_amount_mismatch` audit

### Blast-radius (+соседи)

- `test/integration/block_f_stock_flow_test.rb` — soft-fail R5
- `test/jobs/payments/tbank_callback_job_test.rb` — A5 CONFIRMED×stock

## Не ломать

1. Happy path: CONFIRMED → succeeded + accepted + **deduct при достаточном стоке**
2. Amount mismatch по-прежнему **не** подтверждает платёж
3. Subscription intent (#78) — closed + fulfill, **не** barista accepted
4. Failed/REJECTED → cancel + journal как сейчас

## Проверка

```bash
# G1 — матрица A
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

- [x] T-A1a…T-A6b (+ T-A5*) зелёные (Local G1 suite 83 PASS)
- [x] updater: deduction **не** откатывает `with_lock` txn оплаты
- [x] нет `find_or_create(qty:0)`→Error
- [x] barista / OrderCreator / updater — одна политика
- [x] blank Amount / mismatch — report/audit
- [x] cancelled/closed + succeeded — не quiet
- [ ] `/regress` G2 PASS · GATES G1–G3 met · G4 abandoned (L)
- [ ] REVIEW: таблица A1–A6 \| PASS · **без deploy**

## Next

`/regress`
