# todo — B2.2 этап 1 · единый layout `/barista/menu`

| Поле | Значение |
|------|----------|
| **CBR / ID** | B2.2 · Поток 2 · CBR `[ ]` |
| **ТЗ** | [`B2_2_barista_menu_create_merge.md`](../milestones/veha_2/requirements/customer_tasks/B2_2_barista_menu_create_merge.md) |
| **GREEN** | `7c76a125` · Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | mods/qty (2) · sold_out (3) · POS/cash (4) · remove create-order (5) |

## SBR

- [x] **SPEC** (`acddd923`)
- [x] **RED** (`9c0c7801`)
- [x] **GREEN** (`7c76a125`)
- [x] **regress** PASS (62/0)
- [ ] **REVIEW** — in progress (bugbot low fixed · security OK · push CI)

## Bugbot

- low: search empty category headers → fixed `28cca017`

## Проверка

```bash
ruby bin/rails test test/integration/barista_tablet_regression_test.rb test/controllers/barista/orders_controller_test.rb test/services/barista/order_creation_service_test.rb
```
