# todo — #93 TASK_93-E: Init / идемпотентность оплаты (shop)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-E** |
| **Тип** | SBR · hot-path оплата / Init |
| **Статус** | **GREEN** · Next: `/regress` |
| **RED** | `0a7e72ba` |
| **GREEN** | `2eb22c71` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата E1–E4 · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта E |
| **GATES** | [`session/GATES.md`](GATES.md) · [`GATES-block-E.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-E.md) |
| **Цель** | Повторный Init и гонки не портят живой `provider_payment_id` и не оставляют txn в failed state; HTTP в Т‑Банк не внутри длинной DB-txn `BaseController` на happy path |
| **OUT** | A–D / F–K · deploy (L) · gem’ы оплаты · смена Amount/webhook политики |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1 (E1)** | Живой `provider_payment_id` **не** перетирается повторным Init (widget / SBP / reuse uuid) — иначе webhook теряется |
| **R2 (E2)** | `RecordNotUnique` по `client_order_uuid`: lock / rescue **вне** «грязной» открытой txn (нет `InFailedSqlTransaction` на последующих запросах) |
| **R3 (E3)** | HTTP Init/Т‑Банк **не** держит connection pool ~15s внутри `with_shop_tenant!` txn на happy path (сузить scope или Init после commit GUC-окна) |
| **R4 (E4)** | Тесты: double Init; concurrent same `client_order_uuid` |
| **R5** | Clear pid только на явный fail Charge (#46 Error 119) — **не** на happy re-Init |

Базовый факт кода (SPEC): `OrderCreator` уже делает gateway Init **после** внутренней create-txn; бомба пула — обёртка `Shop::Api::BaseController#with_shop_tenant!` (`transaction` + `SET LOCAL` вокруг **всего** action, включая Init).

## SBR

- [x] PHASE 0 `/start` — бриф TASK_93-E в чате
- [x] `/unlazy` — GATES E `bc6d770e` (G1–G4 unmet · G5→L)
- [x] PHASE 1 `/spec` — этот todo (+ зеркало `todo-block-E.md`)
- [x] PHASE 2 RED — T-E1a/b · T-E2a/b · T-E3a · T-E4a/b падают · коммит `[RED]` `0a7e72ba`
- [x] PHASE 2 GREEN — R1–R5 · коммит `[GREEN]` `2eb22c71` · все T-E* PASS
- [ ] `/regress` — G3 §2.3 + base_controller · GREEN code `2eb22c71` · Entire `01M2SZBBAQEGHNGEJCXYHG76XH`
- [ ] PHASE 3 `/review` — таблица E1–E4 PASS · G4 evidence · push · **без deploy**

## Файлы (ожидаемо)

- `app/controllers/shop/api/base_controller.rb` — E3: сузить `with_shop_tenant!` txn (GUC без длинного hold HTTP)
- `app/services/shop/order_creator.rb` — E2: `RecordNotUnique` / reuse uuid без failed txn; не Init поверх чужого живого pid
- `app/services/shop/widget_payment_initiator.rb` — E1: re-Init с живым pid → resume/return, не overwrite
- `app/services/shop/sbp_payment_initiator.rb` — E1: re-Init → `resume_existing_qr!` (регресс + усиление тестов)
- `test/services/shop/widget_payment_initiator_test.rb` — T-E1a · T-E4a
- `test/services/shop/order_creator_test.rb` — T-E2* · T-E4b
- `test/controllers/shop/api/base_controller_test.rb` — T-E3a (нет open txn вокруг Init HTTP)

### Blast-radius (+соседи)

- `test/integration/shop/api/payment_widget_init_test.rb` / `sbp_payment_init_test.rb` — G1 integration
- `test/integration/shop/api/orders_controller_test.rb` — idempotent `client_order_uuid` (регресс)
- `app/controllers/shop/api/payments_controller.rb` — только если E3 требует skip/around для Init actions (**не** трогать без нужды)

## Матрица приёмки (RED → GREEN)

| ID | Тест | Файл |
|----|------|------|
| T-E1a | widget: pid уже set → второй Init **не** меняет pid / не зовёт новый Init | `widget_payment_initiator_test` |
| T-E1b | SBP: pid set → resume GetQr, pid тот же | `sbp_payment_initiator_test` |
| T-E2a | `RecordNotUnique` на uuid → возвращает existing; нет `InFailedSqlTransaction` | `order_creator_test` |
| T-E2b | после unique-fail последующие AR-запросы в том же request ok (savepoint / вне dirty txn) | ↑ и/или `orders_controller_test` |
| T-E3a | happy-path Init: adapter HTTP при **closed** AR txn (или assert open=false) | `base_controller_test` (+ stub adapter) |
| T-E4a | double Init подряд — один pid, webhook-id стабилен | widget (+ optional integration) |
| T-E4b | concurrent same `client_order_uuid` — один order / без 500 / без failed txn | `order_creator_test` / `orders_controller_test` |

Без **T-E1a + T-E2a + T-E3a + T-E4a** блок не закрыт.

## Не ломать

1. Happy path: первый Init пишет pid → webhook CONFIRMED settles
2. Clear `provider_payment_id` после **fail Charge** (#46 / Error 119) — остаётся
3. SBP resume GetQr при уже живом pid (error 8 / retry) — остаётся
4. RLS: `SET LOCAL app.current_tenant_id` на shop API по-прежнему действует на DB-work запроса
5. Идемпотентность POST orders с `client_order_uuid` (existing tests)

## Проверка

```bash
# G1 — матрица E (Init / pid)
bin/rails test test/services/shop/widget_payment_initiator_test.rb \
  test/integration/shop/api/payment_widget_init_test.rb \
  test/services/shop/sbp_payment_initiator_test.rb \
  test/integration/shop/api/sbp_payment_init_test.rb

# G2 — race / uuid + G3 зона §2.3 (/regress)
bin/rails test test/integration/shop/api/orders_controller_test.rb \
  test/services/shop/order_creator_test.rb \
  test/controllers/shop/api/base_controller_test.rb \
  test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb
```

## DoD блока E

- [ ] T-E1a/b · T-E2a/b · T-E3a · T-E4a/b зелёные
- [ ] G4 REVIEW: cite — HTTP Init вне длинной `base_controller` txn
- [ ] Повторный Init не теряет webhook (живой pid)
- [ ] Пул не держит ~15s HTTP внутри txn на happy path
- [ ] G5 Fly → L (не блокер E)

> Параллельные чаты: канон SPEC E также в `artifacts/critical_path_hardening/todo-block-E.md` — не затирать чужим блоком без restore.
