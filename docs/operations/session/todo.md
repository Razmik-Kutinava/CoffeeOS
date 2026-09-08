# todo — B2.2 этап 1 · единый layout `/barista/menu`

| Поле | Значение |
|------|----------|
| **CBR / ID** | B2.2 · Поток 2 · CBR `[ ]` |
| **ТЗ** | [`B2_2_barista_menu_create_merge.md`](../milestones/veha_2/requirements/customer_tasks/B2_2_barista_menu_create_merge.md) |
| **Макет** | [`customer_mockup_menu_cards_checkout.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b22_menu_create_merge_2026-06-10/customer_mockup_menu_cards_checkout.png) |
| **Цель** | Dual-pane `/barista/menu`: карточки + cart panel; create-order жив |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | mods/qty (2) · sold_out PATCH (3) · POS/cash (4) · remove create-order (5) · Сбер (6+) |

## Карта этапов

| Этап | Статус |
|------|--------|
| 0 stage0 | DONE |
| **1 layout** | **GREEN** ← ждёт `/regress` |
| 2–5 | TODO |

## SBR

- [x] **SPEC** (`acddd923`)
- [x] **RED** (`9c0c7801`)
- [x] **GREEN** (`7c76a125` · Entire `01M1ZZXV23N5BFK4SGDQV0H4KG`)
- [ ] **regress** → `/regress`
- [ ] **REVIEW**

## Файлы (ожидаемо)

- `app/views/barista/menu/index.html.erb` — dual-pane
- `app/controllers/barista/menu_controller.rb` — menu + `@cart` session
- `app/views/barista/menu/_product_card.html.erb` — NEW
- `app/views/barista/menu/_cart_panel.html.erb` — NEW
- `test/integration/barista_tablet_regression_test.rb` — assert layout
- `docs/operations/session/todo.md` — этот файл

### Blast-radius

- `app/views/barista/orders/new.html.erb` — донор; не удалять
- `app/controllers/concerns/barista/menu_catalog_loadable.rb` — reuse
- `app/views/barista/shared/_sidebar.html.erb` — не трогать

## Не ломать

1. B2.1 табло / OrderBoardBroadcaster
2. OrderCreationService через create-order
3. W1.4 menu hides sold_out
4. RBAC barista + open shift для оформления

## Проверка

```bash
ruby bin/rails test test/integration/barista_tablet_regression_test.rb test/controllers/barista/orders_controller_test.rb test/services/barista/order_creation_service_test.rb
```
