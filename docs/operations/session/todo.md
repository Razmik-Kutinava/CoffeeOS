# todo — Active orders accordion + receipt (#36)

**ТЗ:** [`customer_tasks/Мульти-статусная шторка активных заказов с просмотром состава чека.md`](../milestones/veha_2/requirements/customer_tasks/Мульти-статусная%20шторка%20активных%20заказов%20с%20просмотром%20состава%20чека.md)  
**Артефакты (канон UI):** [`artifacts/active_orders_accordion_receipt/`](../milestones/veha_2/artifacts/active_orders_accordion_receipt/)  
**Фаза:** PHASE 1: SPEC `[x]` (ревизия) · RED `[ ]` · GREEN `[ ]` · REVIEW `[ ]`

---

## SPEC (канон CoffeeOS) — ревизия 2026-07-31

### Бизнес-цель
На витрине PWA — **разворачиваемый аккордеон** активных заказов: статус-лайн (4 шага) + **текстовый чек** (товары, модификаторы, скидки, итог) **без** перехода на `/order/:id`. Без кнопок в блоке чека. Не ломать sticky peek #35.

### Что снято с scope (было в первой редакции)
- ❌ `POST /orders/:id/repeat`
- ❌ «Повторить» / `added_items` / `skipped_items` / стоп-лист soft-skip
- ❌ Snackbar про недоступные позиции / ошибки сети при repeat
- ❌ Изменение логики корзины

### Глобальные ограничения

| Ограничение | Канон |
|---|---|
| `GET /orders/active`, `/history` | только **расширить** ответ |
| Глобальные стили PWA | не трогать; стили в компоненте |
| Блок чека | **только текст** — без кнопок / CTA / ссылок |
| Тема | `#1a1a1a`, `#ff6b35` |
| DDL | **нет** |
| Hot-path | не трогать `OrderCreator` / T-Bank |

### Что уже есть (не дублировать)

| Компонент | Путь | Роль |
|---|---|---|
| Active API | `OrdersController#active` | `{ id, order_id, status, order_number, payment_settled }` — **без** items / totals |
| Order show JSON | `#order_json` | `created_at`, `tenant`, items (`product_name`, qty, price, `selected_modifiers`) — **нет** `product_id` / structured modifiers name+price / subtotal на active |
| Sticky peek #35 | `OrderStatusSheet.svelte` + `orderStatusSheet.js` | peek/hidden, multi, Cable |
| Progress | `orderStatusProgress.js` | 4 шага |

### Gaps (делать)

1. **A1** — расширить `#active`: `created_at`, `sales_point`, `items[]` (`product_id`, `name`, `quantity`, `price`, `modifiers[]`), `subtotal`, `discount`, `total_amount`; **сохранить** ключи #35.
2. **A2** — `modifiers[]` = `{ name, price }` из `order_item.modifier_options` (нормализовать форму).
3. **B1** — карточки: статус-лайн, ETA, №, точка, тогл `>` / `v`.
4. **B2** — `activeExpandedOrderId`: строго один открытый чек.
5. **B3** — чек `max-height: 350px; overflow-y: auto`; шторка/витрина не едут.
6. **B4** — текстовая структура позиции: название → модификаторы → кол-во → цена → скидка → итог строки (**без** кнопок).
7. **B5** — низ чека: Subtotal / Discount / Total Amount.
8. **Не** второй sticky — extend `#35` режимом expanded / дочерний accordion.
9. **File-size:** controller 266 / sheet 251 — presenter + split FE, не раздувать.

### Маппинг (ТЗ → CoffeeOS)

| ТЗ | CoffeeOS |
|---|---|
| `ActiveOrdersAccordion` | `app/frontend/components/ActiveOrdersAccordion.svelte` (+ partials) внутри `OrderStatusSheet` |
| Jest/React/`src/…` | `test/javascript/active_orders_accordion_*.mjs` (`node --test`) |
| RSpec | `test/integration/shop/api/active_orders_test.rb` (+ unit presenter при выносе) |
| `sales_point` | как `tenant_pickup_json` (`name`, `address`, `city`) |
| `subtotal` / `discount` / `total_amount` | из order: сумма позиций / `discount_amount` / `final_amount` (сверить schema) |
| `modifiers[].name/price` | из `modifier_options["selected_modifiers"]` — нормализовать в presenter |
| «кнопка с текстом» (оранж. справа) | **вне** блока чека на макете; тексты не заданы → stub/backlog, не блокер exit criteria |

### Архитектура GREEN

| Шаг | Слой | Код | Тесты |
|-----|------|-----|-------|
| **A1** | BE | `Shop::ActiveOrdersPresenter` + `#active` preload items | active: fields + totals; no N+1 |
| **A2** | BE | modifiers `{name, price}` в том же presenter | item with syrups; item without mods → `[]` |
| **B1** | FE | accordion rows + progress reuse | JS render |
| **B2** | FE | `activeExpandedOrderId` | open B closes A |
| **B3** | FE | receipt scroll CSS | class/assert |
| **B4** | FE | text lines only | no button in receipt DOM |
| **B5** | FE | footer totals | zero discount OK |

### UI / скрины (канон)

| Скрин | Ожидание |
|---|---|
| `01_single_order_expanded.png` | 1 заказ, expanded, статус-лайн, текстовый чек |
| `02_multi_order_accordion_one_expanded.png` | 2 заказа; один `v`, другой `>` |

### RLS
- `tenant_id` + `source: mobile` + customer session как `#active`
- Без `unscoped`

### Риски

| Риск | Митигация |
|---|---|
| Сломать #35 peek | регрессия sheet + active tests |
| Форма modifiers в БД неоднородна | нормализация в presenter + тесты empty/with |
| Оранж. кнопки без текста | backlog |
| File size | presenter + FE split |

### Вне scope
- Repeat / корзина / стоп-лист soft-skip
- `/history` enrich (не в чеклисте)
- Тексты оранжевых кнопок справа от статус-лайна

---

## Чеклист выполнения (SBR)

### PHASE 1: SPEC
- [x] Анализ + ревизия ТЗ (receipt, без repeat)
- [x] todo.md + SESSION_STATE
- [x] СТОП → намерение на RED

### PHASE 2: RED
- [x] A1–A2 failing tests (Rails) — `active_orders_receipt_test.rb`
- [x] B1–B5 failing tests (JS) — `active_orders_accordion_test.mjs`
- [ ] commit `test: … [RED]`

### PHASE 2: GREEN
- [ ] A1–A2 presenter + active payload
- [ ] B1–B5 accordion + text receipt
- [ ] регрессия shop
- [ ] commit `feat: … [GREEN]`

### PHASE 3: REVIEW
- [ ] N+1 / RLS / rubocop
- [ ] CHANGELOG + HANDOFF
- [ ] MCP Fly vs 2 скрина (после deploy-апрува)

---

## Команды проверки

```bash
bin/rails test test/integration/shop/api/active_orders_test.rb
node --test test/javascript/order_status_sheet_test.mjs test/javascript/active_orders_accordion_test.mjs
bin/rails test test/integration/shop/
```
