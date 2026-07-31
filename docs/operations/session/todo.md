# todo — Quick Repeat Bottom Sheet (ревизия #14 · active order hide)

**ТЗ:** [`customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](../milestones/veha_2/requirements/customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)  
**Артефакты (канон UI):** [`artifacts/quick_repeat_bottom_sheet/`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/) — скрины `*_2026-07-31.png`  
**Фаза:** PHASE 1–3 SPEC/RED/GREEN/REVIEW `[x]` · push/deploy/MCP `[ ]`

---

## SPEC (канон CoffeeOS) — 2026-07-31

### Бизнес-цель
Секция «повторить» (1–3 мини-карточки) в CartSheet: peek / expanded / hidden + «в 1 клик».  
**NEW (ревизия):** если у клиента есть **активный** заказ — секцию **не показывать** (`frequent_items: []`, `has_active_order: true`), т.к. покупка уже идёт. После `issued`/`closed`/`cancelled` — снова показывать топ без перезапуска PWA.

### Scope ревизии (не rewrite с нуля)

| Уже есть (reuse) | Делаем в этой ревизии |
|---|---|
| `Shop::CustomerFrequentProductsService` (45д / топ-3 / mods) | `HIDE_REPEAT_STATUSES` + early `[]` |
| `GET /shop/api/frequent_products` | поле `has_active_order` |
| кэш `shop/freq/v2/…` TTL 30м | bump **v3** (payload с флагом) + bust на barista status / cancel |
| `shopFrequentCache` / `frequentRepeatStore` / `RepeatSection` | honor flag → clear stale cache → hide slots |
| CartSheet slots (empty/peek/expanded) | gate на `!hasActiveOrder && frequentCount > 0` |
| OrderStatusSheet #35 / accordion #36 | **не мержить** в CartSheet; peek: статус побеждает, повтор скрыт |
| Скрины 01–06 канон | UI приёмка = новые PNG (не MCP 07-21) |

### Вне scope (не трогать без отдельного go)
- DDL / схема orders/items/products
- Rewrite категорий / каталога (шаг 2 ТЗ — уже покрыт existing categories path)
- Vitest/RSpec пути из ТЗ — маппинг на Minitest + `node --test`
- Смена guest→401 (канон: гость 200 + `frequent_items: []`)
- Полный redesign CartSheet под скрины 02/03 (только поведение hide + регрессия layout)

### Глобальные ограничения

| Ограничение | Канон |
|---|---|
| DDL | **нет** |
| Тяжёлые JOIN | **нет** — как сейчас, flat queries + Ruby |
| Лимиты | константы сервиса (`WINDOW_DAYS`, `MAX_REPEAT_ITEMS`, `CACHE_TTL`, **`HIDE_REPEAT_STATUSES`**) |
| FE cache deps | только паттерн `shopLocalStorage` / `shopFrequentCache` |
| Hot-path | OrderCreator / PaymentStatusUpdater / barista status — только `bust_cache!` (rescue) |
| #35 / #36 | не ломать sticky status / accordion |

### Маппинг статусов (ТЗ → CoffeeOS)

| ТЗ | CoffeeOS `Order.status` |
|---|---|
| `created` | **не включаем** как hide-trigger: у нас `pending_payment` = ещё не оплатил → повтор **оставляем** (иначе peek без статуса #35 и без повтора) |
| `accepted` | `accepted` |
| `cooking` | `preparing` |
| `ready` | `ready` |
| `completed` | `issued` / `closed` (терминал → показать повтор) |
| `cancelled` | `cancelled` (терминал → показать повтор) |

**Канон hide:** `HIDE_REPEAT_STATUSES = %w[accepted preparing ready]` — **совпадает** с `Order.active` / `GET /orders/active` (#35).  
Константа в сервисе (не хардкод в контроллере); при желании позже выровнять с `Order.active` одним источником.

### Что уже есть (не дублировать)

| Компонент | Путь | Роль |
|---|---|---|
| Frequent service | `app/services/shop/customer_frequent_products_service.rb` | топ-3; **нет** active gate |
| API | `app/controllers/shop/api/frequent_products_controller.rb` | `{ frequent_items, categories }` |
| Cache bust | OrderCreator + PaymentStatusUpdater | **нет** bust на barista → issued/cancelled |
| FE store | `app/frontend/lib/frequentRepeatStore.js` | refresh без `has_active_order` |
| Repeat UI | `RepeatSection.svelte` + slots в `CartSheet.svelte` | gate только `frequentCount` / `!onCheckout` |
| Active orders | `#active` + OrderStatusSheet | независимый стек |

### Gaps (делать)

1. **B1** — сервис: `has_active_order?` + если true → `call`/`cached_call` отдают пустой список (или кэш хранит `{ has_active_order, items }` — см. B3).
2. **B2** — API: JSON `{ has_active_order:, frequent_items:, categories: }`; при true — `frequent_items` всегда `[]`.
3. **B3** — кэш **v3** ключ `shop/freq/v3/#{tenant}/#{customer}`: значение `{ has_active_order:, items: }` (или эквивалент); TTL 30м.
4. **B4** — bust: оставить OrderCreator + PaymentStatusUpdater; **добавить** в `Barista::OrderStatusUpdateService` (и cancel-path, если отдельный) при смене статуса, когда customer_id есть.
5. **F1** — `shopFrequentCache` / store: читать/писать `has_active_order`; при true — очистить items в UI сразу.
6. **F2** — CartSheet: не монтировать RepeatSection если `hasActiveOrder`; heights без repeat bump.
7. **F3** — после Cable terminal (#35) или visibility: `refreshFrequentProducts` (если ещё нет) — чтобы повтор вернулся без reload.
8. **Тесты** — только NEW поведение + регрессия frequent*; не переписывать все 12 шагов ТЗ с нуля.

### Архитектура GREEN

| Шаг | Слой | Код | Тесты |
|-----|------|-----|-------|
| **B1** | BE service | `HIDE_REPEAT_STATUSES` + early return `[]` | `customer_frequent_products_service_test` — active → []; no active → top-3 |
| **B2** | BE API | `has_active_order` в index | `frequent_products_test` — flag + empty items |
| **B3** | BE cache | key v3 + payload | `customer_frequent_products_cache_test` |
| **B4** | BE bust | barista status update | cache test / barista service test — bust on issued/cancelled |
| **F1** | FE store/cache | flag + clear | `quick_repeat_frequent_cache_test` + optional `test/javascript` |
| **F2** | FE CartSheet | hide slots | `quick_repeat_section_test` / layout canon |
| **F3** | FE refresh | terminal → refresh | JS или integration source assert |

### UI / скрины (канон приёмки)

| Скрин | Ожидание |
|---|---|
| `01_…` | каталог + секция «повторить» (нет активного заказа) |
| `02_…` / `03_…` | expanded: корзина/новые позиции + «повторить» внизу (нет активного) |
| `04_…` | hidden, один напиток — без обязательной секции повтора в полосе |
| `05_…` | peek: 3 превью + «+цена» (нет активного) |
| `06_…` | «полатить в 1 клик» на карточках повтора |
| `07_customer_feedback_status_sheet_not_full_width_2026-07-31.png` | при активном заказе Quick Repeat скрыт во всех режимах; #35/#36 status sheet на всю ширину, без боковой CartSheet |

### RLS
- Как сейчас: tenant + mobile history + customer session / GuestCustomerResolver
- Active-check: те же `tenant_id` + `customer_id`, без `unscoped`

### Риски

| Риск | Митигация |
|---|---|
| `pending_payment` как «created» → пустой peek | **не** в HIDE_REPEAT (решение SPEC) |
| Stale Rails cache после issued | bust в barista status |
| Stale localStorage | FE clear при `has_active_order: true` |
| Сломать #35 peek / z-index | full-width `OrderStatusSheet`; явный `hidden/peek/expanded`; z60 сохранить |
| `RepeatSection` / CartSheet размер | минимальный gate, без нового монолита |
| Guest 401 из ТЗ | не менять (200 + []) |

### Маппинг тестов (ТЗ → CoffeeOS)

| ТЗ | CoffeeOS |
|---|---|
| RSpec service | `test/services/shop/customer_frequent_products_service_test.rb` |
| RSpec request | `test/integration/shop/api/frequent_products_test.rb` |
| RSpec order cache | `test/services/shop/customer_frequent_products_cache_test.rb` + barista bust |
| Vitest FE | `test/integration/shop/quick_repeat_*_test.rb` + при необходимости `test/javascript/*_test.mjs` |
| Регрессия зоны | `bin/rails test test/integration/shop/` (focused frequent* + active_orders*) |

### Порядок RED → GREEN
1. RED B1–B4 (падающие тесты active/flag/bust) → commit `[RED]`
2. GREEN B1–B4 → регрессия frequent*
3. RED F1–F3 + full-width/status modes → commit `[RED]`
4. GREEN F1–F3 + full-width/status modes → layout canon + REVIEW

---

## Чеклист выполнения

### PHASE 1 SPEC
- [x] Разведка + решения (статусы, v3 cache, reuse)
- [x] `todo.md` / SESSION_STATE

### PHASE 2 BUILD
- [x] RED B1–B4 (тесты написаны, падают — ожидаемо)
- [x] GREEN B1–B4
- [x] RED F1–F3
- [x] GREEN F1–F3
- [x] Регрессия зоны shop (quick_repeat* + frequent*)

### PHASE 3 REVIEW
- [x] Sanity N+1 / RLS / file-size
- [x] CHANGELOG / HANDOFF
- [ ] MCP Fly vs скрины (после deploy-апрува)
