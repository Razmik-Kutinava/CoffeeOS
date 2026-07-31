# todo — Active orders accordion + repeat (#36)

**ТЗ:** [`customer_tasks/Мульти-статусная шторка активных заказов с повторной покупкой.md`](../milestones/veha_2/requirements/customer_tasks/Мульти-статусная%20шторка%20активных%20заказов%20с%20повторной%20покупкой.md)  
**Артефакты (канон UI):** [`artifacts/active_orders_accordion_repeat/`](../milestones/veha_2/artifacts/active_orders_accordion_repeat/)  
**Фаза:** PHASE 1: SPEC `[x]` · RED `[ ]` · GREEN `[ ]` · REVIEW `[ ]`

---

## SPEC (канон CoffeeOS)

### Бизнес-цель
На витрине PWA — **разворачиваемый аккордеон** активных заказов: статус-лайн (4 шага), чек состава, кнопка **«Повторить»** по позиции → в корзину с учётом стоп-листа. Не блокировать каталог; не ломать sticky peek из #35.

### Глобальные ограничения (из ТЗ + CoffeeOS)

| Ограничение | Канон |
|---|---|
| `GET /orders/active`, `/history` | **не ломать** маршрут/форму ответа — только **расширить** поля |
| Глобальные стили PWA | не трогать; стили только в компоненте шторки |
| Логика корзины | не менять `CartService` API; repeat **вызывает** `CartService#add!` |
| Тема | `#1a1a1a`, акцент `#ff6b35` |
| DDL | **нет** — Migration Gate не нужен |
| Hot-path | не трогать `OrderCreator` / T-Bank callback |

### Что уже есть (не дублировать)

| Компонент | Путь | Роль |
|---|---|---|
| Active API | `OrdersController#active` | `{ orders: [{ id, order_id, status, order_number, payment_settled }] }` — **без** items/sales_point |
| Order show JSON | `#order_json` | `created_at`, `tenant`, items без `product_id` |
| Sticky peek #35 | `OrderStatusSheet.svelte` (~251) + `orderStatusSheet.js` (~73) | peek/hidden, multi-order, Cable, GET active |
| Progress 4 шага | `orderStatusProgress.js` | Принят→Оплачен→Готовится→Готов |
| Cart add | `POST /shop/api/cart/add` → `Shop::CartService#add!` | стоп-лист → 404 hard-fail |
| Stop-list | `ProductTenantSetting.available` | `is_enabled && !is_sold_out` |
| Ownership | `order_visible_to_session_customer?` | mismatch → **404** (не 403) |
| Quick Repeat | `RepeatSection` / `frequent_products` | **другая** поверхность (корзина) — не смешивать |

### Gaps (делать)

1. **A1** — расширить `#active`: `created_at`, `sales_point` (из `tenant_pickup_json`), `items[]` с `product_id`, `name`, `quantity`, `price`, `modifiers[]`; **сохранить** текущие ключи (#35).
2. **A2** — `POST /shop/api/orders/:id/repeat` + `Shop::OrderRepeatService` → `CartService#add!` → `{ added_items, skipped_items }`.
3. **A3** — soft-skip стоп-листа в repeat (не hard 404 на всю операцию).
4. **B1–B3** — expanded-аккордеон: один `expandedOrderId`; чек `max-height: 350px; overflow-y: auto`; тогл `>` / `v`.
5. **B4–B6** — «Повторить» (позиция), snackbar skipped, ошибка сети.
6. **Не** плодить второй sticky widget — **расширить** `#35` sheet режимом `expanded` (или дочерний accordion внутри).
7. **File-size:** `orders_controller.rb` 266 / `OrderStatusSheet.svelte` 251 — **не раздувать**; вынести presenter/service + дочерние `.svelte` / lib.

### Маппинг путей (ТЗ → CoffeeOS)

| ТЗ (шаблон) | CoffeeOS |
|---|---|
| `ActiveOrdersAccordion` | `app/frontend/components/ActiveOrdersAccordion.svelte` (+ partials) внутри `OrderStatusSheet` |
| Jest / React / `src/components/…` | **не использовать** → `test/javascript/active_orders_accordion_*.mjs` (`node --test`) |
| RSpec `spec/requests/…` | `test/integration/shop/api/active_orders_test.rb` + `order_repeat_test.rb` |
| `yarn test` / `yarn tsc` | `node --test test/javascript/…` + `bin/rails test …` (tsc не канон shop FE) |
| 403 Forbidden (чужой заказ) | **отклонение:** как `#show` — **404** `"Order not found"` (не светить существование); зафиксировать в тесте |
| auth token | session + `Shop::CustomerSession` / `order_visible_to_session_customer?` (как show) |
| `sales_point` | объект как `tenant_pickup_json` (`name`, `address`, `city`) под ключом `sales_point` |
| `modifiers[]` | из `order_item.modifier_options["selected_modifiers"]` |
| «кнопка с текстом» (оранж. справа на макете) | **не в чеклисте A/B** — stub/placeholder или backlog до уточнения заказчика; не блокирует exit criteria |

### Решение по «Повторить» (позиция vs весь заказ)

Макет: кнопка **на каждой строке** чека.  
ТЗ A2: `POST …/repeat` копирует items заказа.

**Канон SPEC:**

- `POST /shop/api/orders/:id/repeat`
- Body опционально: `{ "product_id": "<uuid>" }` **или** `{ "order_item_id": "<uuid>" }`
- Без body / без фильтра → все позиции заказа
- С фильтром → только эта позиция (и её модификаторы из order_item)
- Цены — **актуальные** из `ProductTenantSetting` / `CartService#add!` (не историческая цена чека)
- Ответ всегда `{ added_items: [...], skipped_items: [...] }` (+ опц. `cart`/`total` для FE refresh — если удобно, без ломки контракта ТЗ)

### Архитектура GREEN (по блокам)

| Шаг | Слой | Код (цель) | Тесты (RED→GREEN) |
|-----|------|------------|-------------------|
| **A1** | BE | `#active` + `includes(:order_items)`; presenter `Shop::ActiveOrdersPresenter` (не раздувать controller) | `active_orders_test` — поля items/sales_point/created_at; N+1 нет |
| **A2** | BE | route `post :repeat`; тонкий action → `Shop::OrderRepeatService` | `order_repeat_test` — 200 / 404 / empty items |
| **A3** | BE | в сервисе: PTS.available → skip; иначе `CartService#add!` | sold_out → skipped; все skipped → 200 + empty added |
| **B1** | FE | accordion rows: progress + ETA + № + точка + chevron | JS render 1 order expanded |
| **B2** | FE | `expandedOrderId` — только один открыт | JS: open B closes A |
| **B3** | FE | receipt container `max-height: 350px; overflow-y: auto` | JS/class assert + mount acceptance |
| **B4** | FE | кнопка «повторить» → POST repeat(+product_id) → refresh cart store | JS mock 200 |
| **B5** | FE | snackbar текст из ТЗ при `skipped_items.length > 0` | JS |
| **B6** | FE | сеть/500 → toast ошибки; корзина без изменений | JS |

### UI / скрины (критерий приёмки)

| Скрин | Ожидание |
|---|---|
| `01_single_order_expanded.png` | 1 заказ, expanded, статус-лайн 4 шага, чек + «повторить» |
| `02_multi_order_accordion_one_expanded.png` | ≥2 заказа; один `v` expanded, другой `>` collapsed |

Coexistence: не ломать CartSheet z-index/#35 peek; expanded — **дополнение** к sticky status (режим sheet / высота), каталог кликабелен где не перекрыт шторкой.

### RLS / тенант

- Все запросы — `tenant_id: @shop_tenant.id`, `source: :mobile`
- Repeat: заказ виден через `order_visible_to_session_customer?` (или тот же customer_id что `#active`)
- Cart add — существующий `CartService` с `Current.tenant_id` / session tenant
- Без `unscoped` / `row_security off`

### Риски

| Риск | Митигация |
|---|---|
| Раздуть `OrdersController` / `OrderStatusSheet` >200 | Presenter + OrderRepeatService; FE split accordion |
| Сломать #35 peek / Cable | Регрессия `order_status_sheet_*` + `active_orders_test` |
| Путаница с Quick Repeat | Отдельный endpoint/UI; не трогать `RepeatSection` |
| Per-item vs whole-order | optional `product_id` / `order_item_id` в body |
| Оранж. кнопки на макете без текста | backlog / stub; не блокер A/B чеклиста |

### Вне scope (backlog при необходимости)

- Реальные тексты двух оранжевых кнопок справа от статус-лайна
- Изменение `/history` payload (ТЗ разрешает расширять, но чеклист не требует)
- PKCS7 / Wallet (#35 backlog)
- Push copy / новый Cable channel

---

## Чеклист выполнения (SBR)

### PHASE 1: SPEC
- [x] Анализ reuse/#35 + gaps
- [x] todo.md + SESSION_STATE
- [ ] СТОП → намерение на RED

### PHASE 2: RED
- [ ] A1–A3 failing tests (Rails)
- [ ] B1–B6 failing tests (JS)
- [ ] commit `test: … [RED]`

### PHASE 2: GREEN
- [ ] A1 expand active payload
- [ ] A2+A3 OrderRepeatService + route
- [ ] B1–B6 accordion + repeat UI
- [ ] регрессия зоны shop
- [ ] commit `feat: … [GREEN]`

### PHASE 3: REVIEW
- [ ] N+1 / RLS / rubocop
- [ ] CHANGELOG + HANDOFF
- [ ] MCP Fly vs 2 скрина (после deploy-апрува)

---

## Команды проверки (целевые)

```bash
bin/rails test test/integration/shop/api/active_orders_test.rb test/integration/shop/api/order_repeat_test.rb test/services/shop/order_repeat_service_test.rb
node --test test/javascript/order_status_sheet_test.mjs test/javascript/active_orders_accordion_test.mjs
bin/rails test test/integration/shop/
```
