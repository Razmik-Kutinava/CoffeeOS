# todo — B2.2 этап 1 · единый layout `/barista/menu`

| Поле | Значение |
|------|----------|
| **CBR / ID** | B2.2 · Поток 2 (обработка заказа) · реализация CBR `[ ]` |
| **ТЗ** | [`B2_2_barista_menu_create_merge.md`](../milestones/veha_2/requirements/customer_tasks/B2_2_barista_menu_create_merge.md) |
| **Артефакты** | [`b22_stage0_mapping_2026-06-10.json`](../milestones/veha_2/artifacts/demo-feedback/b22_stage0_mapping_2026-06-10.json) · макет [`customer_mockup_menu_cards_checkout.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b22_menu_create_merge_2026-06-10/customer_mockup_menu_cards_checkout.png) |
| **Тип** | Feat / barista hot-path (табло · смена · каталог W1.4) |
| **Цель (DoD этапа 1)** | `/barista/menu` = dual-pane: сетка карточек (фото+название+цена) + панель корзины (позиции/итог; «Оплатить» disabled/placeholder). Каталог через `MenuCatalogLoadable` + `Shop::Catalog.tenant_menu`. `create-order` **жив**. |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **OUT (этап 1)** | модификаторы/qty/промо (2) · sold_out PATCH (3) · POS stub / убрать cash (4) · удаление create-order + sidebar (5) · реальный Сбер (6+) · Shop PWA / TbankAdapter · gem’ы эквайринга |

## Карта этапов B2.2 (= карта SBR)

| Этап | Содержание | Статус |
|------|------------|--------|
| 0 | Маппинг, макеты, stage0 JSON | **DONE** |
| **1** | Единый layout: сетка + cart panel | **SPEC** ← этот проход |
| 2 | Модификаторы, qty ±, сумма, промокод | TODO |
| 3 | Чек-бокс «В наличии» → PATCH `is_sold_out` | TODO |
| 4 | «Оплатить» → PosPaymentService stub; без cash | TODO |
| 5 | Убрать create-order из nav; redirect; smoke/MCP | TODO |
| 6+ | Реальный Сбер POS | OUT MVP |

Один SBR = один этап. После REVIEW этапа 1 — стоп; этап 2 отдельным намерением.

## Решения SPEC (зафиксировано)

| Тема | Решение |
|------|---------|
| Layout | Dual-pane по макету `customer_mockup_menu_cards_checkout.png` (Hotwire/ERB/TUI как соседние barista views; не pixel-perfect DS) |
| Корзина | `session[:barista_cart]` как в `OrdersController#new`; можно читать/показывать; add/qty — этап 2 |
| Каталог | Только `MenuCatalogLoadable` + `Shop::Catalog.tenant_menu` (W1.4) — не дублировать источник |
| Смена | Поведение как `OrdersController#new` (`@shift = current_shift`; authorize create только если смена есть; без open shift — нельзя оформить, UI не ломает просмотр) |
| create-order | **Не** удалять, **не** трогать sidebar в этапе 1 |
| Оплатить | Кнопка в панели может быть disabled / placeholder — без POS |
| Стек | Rails + Hotwire/Turbo (+ Stimulus если уже принято). **Не** Svelte CartSheet |
| Тесты | Расширить `barista_tablet_regression_test` (+ controller test menu при нужде) |

## SBR

- [x] **SPEC** (этот файл)
- [ ] **RED** — падающие тесты: menu page = карточки + cart panel
- [ ] **GREEN** — dual-pane layout + cart из session + regress
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI

## Файлы (ожидаемо)

- `app/views/barista/menu/index.html.erb` — dual-pane: сетка карточек + панель корзины
- `app/controllers/barista/menu_controller.rb` — `load_tenant_menu!` + `@cart` из `session[:barista_cart]` (+ shift как new)
- `app/views/barista/menu/_product_card.html.erb` — **NEW** partial карточки (фото, имя, цена)
- `app/views/barista/menu/_cart_panel.html.erb` — **NEW** partial корзины (позиции, итог, Оплатить placeholder)
- `test/integration/barista_tablet_regression_test.rb` — assert карточки + cart panel на `/barista/menu`; не ломать sold_out hide / create-order
- `docs/operations/session/todo.md` — этот SPEC

### Blast-radius (соседи — read/донор, не менять без нужды)

- `app/views/barista/orders/new.html.erb` — донор UX сетки/корзины; **не удалять**
- `app/controllers/concerns/barista/menu_catalog_loadable.rb` — только read/reuse
- `app/views/barista/shared/_sidebar.html.erb` — этап 1: **не трогать**

## Не ломать

1. **B2.1 табло** — `OrderBoardBroadcaster`, dashboard, звук, статусы
2. **`Barista::OrderCreationService`** через create-order (`source: manual`) ещё работает
3. **W1.4** — menu hides sold_out = как витрина (`barista_tablet_regression_test` «menu hides sold out»)
4. **RBAC + смена** — только barista (+ shift для оформления); manager не создаёт через barista endpoint

## Проверка

```bash
ruby bin/rails test test/integration/barista_tablet_regression_test.rb test/controllers/barista/orders_controller_test.rb test/services/barista/order_creation_service_test.rb
```

Local/MCP после GREEN: barista → `/barista/menu` → карточки + cart panel; `/barista/create-order` ещё открывается.

## Acceptance (RED→GREEN этап 1)

1. GET `/barista/menu` рендерит product cards (имя/цена; фото если есть) и cart panel
2. Корзина читается из `session[:barista_cart]` (пустая — пустая панель)
3. Каталог = `Shop::Catalog.tenant_menu` path (sold_out hide регрессия зелёная)
4. create-order + OrderCreationService + табло-регрессия зелёные
5. Нет sold_out PATCH / POS / удаления create-order / убирания cash

## След. этапы (не этот SBR)

- **2** — модификаторы + qty + промо (`customer_mockup_modifiers_acquiring.png`)
- **3** — `ProductAvailabilityController` PATCH `is_sold_out`
- **4** — `PosPaymentService` stub; убрать cash
- **5** — sidebar + redirect create→menu + smoke/MCP + CBR галочки
