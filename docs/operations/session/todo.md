# todo — Quick Repeat Bottom Sheet (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](../milestones/veha_2/requirements/customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)  
> **Скрины:** [`artifacts/quick_repeat_bottom_sheet/`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/README.md)  
> Предыдущая фича (Bottom sheet expanded grid): закрыта 2026-07-21, deploy `[ ]` по апруву.

## Текущая фаза

**PHASE 2: BUILD — F3-RED `[x]` 2026-07-21 (5 runs / 3 failures — qty-персиста нет, ожидаемо) · Gate 2: жду go на F3-GREEN**

## Маппинг ТЗ → наш стек (решения SPEC)

| ТЗ | Наш стек | Почему |
|---|---|---|
| RSpec `spec/…` | Minitest: `test/services/shop/`, `test/integration/shop/api/`, `test/integration/shop/` | В репо нет RSpec; канон — зеркало `test/` (все прошлые задачи так) |
| Vitest + Svelte Testing Library `src/lib/…` | Integration-тесты на разметку/логику Svelte-исходников (паттерн `bottom_sheet_heights_canon_test.rb`, `b113_s2b_mode_persistence_test.rb`) | Vitest-инфраструктуры нет; лимит < 50 мс и 60fps — MCP-чек на Fly, не unit |
| `GET /shop/api/frequent_products` → 401 без авторизации | Гость без `customer_id` → `{ frequent_items: [] }` (как `orders#history` → `[]`) | Витрина гостевая (`Shop::CustomerSession`), 401 сломал бы UX каталога |
| «Timecop» | `travel_to` (ActiveSupport::Testing::TimeHelpers) | Стандарт Minitest/Rails |
| tsc | eslint + svelte compile check | Фронт на JS (решение владельца в прошлой задаче) |
| Bottom sheet «занимает ~90% высоты» / «peek ~200-250px» | Канон высот шторки НЕ трогаем (`bottom_sheet_heights_canon_test.rb`: 52/56 · 34/38 · 24) | Канон принят владельцем 2026-07-21; секция «повторить» встраивается в существующие режимы |

## Ограничения (проверено по коду)

- Схема БД не меняется: агрегация по `orders` (customer_id, tenant_id, source: :mobile, created_at) + `order_items` (`product_id`, `modifier_options` jsonb, `product_name`) — всё есть.
- Без тяжёлых JOIN: 2 запроса (orders window → order_items по order_ids) + агрегация в Ruby (`group_by` по `[product_id, modifier_options]`) — паттерн `coffeeos-performance`.
- Лимиты в константах сервиса: `WINDOW_DAYS = 45` (диапазон 30–60), `MAX_REPEAT_ITEMS = 3`, `CACHE_TTL = 30.minutes`.
- RLS: сервис вызывается из `Shop::Api::BaseController` (tenant context уже установлен); запросы только с `tenant_id`.
- `CartSheet.svelte` = 514 строк (> 200) — секцию «повторить» НЕ вписываем внутрь: отдельный компонент `RepeatSection.svelte` + отдельный store/lib.
- Hot-path: инвалидация кэша касается `Shop::OrderCreator` — минимальный дифф (одна строка bust после commit), регрессия оплаты обязательна.

## Пункты SBR (пары RED → go → GREEN)

### B1 — сервис частых товаров (ТЗ Шаг 1)
- [x] RED 2026-07-21: `test/services/shop/customer_frequent_products_service_test.rb` — 12 тестов (агрегация 3/5 заказов · пустой массив · топ-3 по частоте · свежесть при равной частоте · раздельные модификаторы · окно WINDOW_DAYS · только mobile · без pending/cancelled · изоляция тенантов · disabled исключён · image_url nil placeholder · лимиты в константах). Прогон: **12 runs / 12 errors** — все `NameError: uninitialized constant Shop::CustomerFrequentProductsService` (намеренный RED `[TDD]`, не ISSUES)
- [x] GREEN 2026-07-21: `app/services/shop/customer_frequent_products_service.rb` (86 строк) — `WINDOW_DAYS=45`, `MAX_REPEAT_ITEMS=3`, `COUNTED_STATUSES` (без pending/cancelled); 4 плоских запроса без JOIN (orders pluck → order_items pluck → PTS index_by → products index_by), группировка `[product_id, modifier_options]`, сортировка частота↓ свежесть↓. Тесты **12 runs / 0 fail**; регрессия `test/services/shop/` **103 runs / 0 fail**; rubocop 0 offenses

### B2 — категории витрины (ТЗ Шаг 2): переиспользуем существующее
- [ ] Существующий `shop/api/categories` + `products` уже отдают категории/товары с кэшем 5 мин и placeholder — НОВЫЙ сервис не пишем
- [ ] RED/GREEN: тест-фиксация формата payload `frequent_products` (см. B4) — категории в ответе из существующего пути

### B3 — кэш + инвалидация (ТЗ Шаг 3)
- [x] RED 2026-07-21: `test/services/shop/customer_frequent_products_cache_test.rb` — 6 тестов (формат ключа + CACHE_TTL=30 мин · cached_call пишет в Rails.cache и отдаёт stale внутри TTL · истечение TTL через `travel 31.minutes` · `bust_cache!` · инвалидация в `OrderCreator.call!` · инвалидация в `PaymentStatusUpdater` при succeeded). Прогон: **6 runs / 6 errors** — `NoMethodError: cached_call/cache_key` (намеренный RED `[TDD]`)
- [x] GREEN 2026-07-21: `cache_key`/`cached_call`/`bust_cache!` (+`CACHE_TTL=30.minutes`) в сервисе; bust-хуки по 1 строке (+комментарий): `OrderCreator#call!` после транзакции · `PaymentStatusUpdater#accept_order_if_paid!`. Тесты **18 runs / 0 fail** (кэш 6 + сервис 12); регрессия: оплата §2.3 **24/0 (2 skips pre-existing)** · T-Bank callback **31/0** · services **112/0**; rubocop 4 файла чист

### B4 — API endpoint (ТЗ Шаг 4)
- [x] RED 2026-07-21: `test/integration/shop/api/frequent_products_test.rb` — 5 тестов (гость → 200 + `frequent_items: []` + categories hash · карточки категорий id/name/price/image_url + nil placeholder · customer после полного checkout-флоу видит frequent_items · изоляция тенантов · неизвестный tenant → error payload). Прогон: **5 runs / 5 failures** — 404, роута нет (намеренный RED `[TDD]`). Грабля env: GET без `as: :json` уходит в SPA catch-all `pages#home` и вешает прогон — во всех тестах `as: :json`
- [x] GREEN 2026-07-21: роут `get "frequent_products"` + `Shop::Api::FrequentProductsController` (52 строки: `cached_call` сервиса + `categories_by_name` — 3 плоских запроса как в categories#index). Тесты **5 runs / 0 fail**; регрессия shop api таргетно: categories 4/0 · products 4/0 · orders 9/0 · mvp_flow 2/0 · tenant_isolation 2/0; rubocop чист. Env: `cart_persistence_test.rb` виснет локально на рендере shell `GET /shop?tenant_id=` (та же 🟡 ISSUES-грабля, не этот дифф — файл не трогает frequent_products)

### F1 — клиентский кэш + инициализация (ТЗ Шаг 5)
- [x] RED 2026-07-21: `test/integration/shop/quick_repeat_frequent_cache_test.rb` — 4 теста (фиксация `shopFrequentCache.js` ключ `coffeeos_shop_frequent_v1` + read/write/clear · фиксация `frequentRepeatStore.js` init-из-кэша + `api("/frequent_products")` + writeFrequentCache · catch не обнуляет секцию · mirror init/refresh/error). Прогон: **4 runs / 3 errors** (ENOENT — файлов нет, намеренный RED `[TDD]`; mirror-тест чистой логики зелёный сразу)
- [x] GREEN 2026-07-21: `shopFrequentCache.js` (20 строк, зеркало shopCartCache) + `frequentRepeatStore.js` (42 строки: stores frequentItems/frequentCategories/frequentLoaded, `initFrequentFromCache` синхронный, `refreshFrequentProducts` фоновый с catch-без-очистки). Тесты **4 runs / 0 fail**; регрессия канона шторки + persistence **9 runs / 0 fail**; esbuild syntax OK

### F2 — секция «повторить» в режимах empty/peek/expanded (ТЗ Шаги 6–8, скрины 01–05)
- [x] RED 2026-07-21: `test/integration/shop/quick_repeat_section_test.rb` — 4 теста (разметка `RepeatSection.svelte`: заголовок «повторить» italic, карточки shop-repeat-card с thumb/«Нет фото»/line-clamp/цена/−1+/slice(0,3), данные из frequentItems · встройка в CartSheet: init+refresh, слоты empty/peek/expanded, НЕ hidden · один drag-handle · mirror видимости). Прогон: **4 runs / 1 failure + 2 errors** (ENOENT компонента + нет слотов — намеренный RED `[TDD]`). Решение: в hidden секцию не показываем — там существующие чипы корзины (скрины 04–05 трактуем как чипы, вопрос заказчику на приёмке)
- [x] GREEN 2026-07-21: `app/frontend/components/RepeatSection.svelte` (~95 строк: заголовок «повторить» italic, до 3 карточек slice(0,3) из frequentItems, thumb/«Нет фото», line-clamp название, цена оранжевым, локальный счётчик −1+ с минимумом 1) + встройка в `CartSheet.svelte`: import + init/refresh в onMount, слоты shop-repeat-slot-empty/peek/expanded перед checkoutBar (hidden не трогали, drag-handle один). Тесты **4 runs / 48 assertions / 0 failures**, регрессия шторки (heights canon + b113 + checkout UX + F1 cache) **24 runs / 263 assertions / 0 failures**, svelte compile обоих файлов OK. Отложено: счётчик пишет только в локальный state — синк с localStorage и add-to-cart идут в F4 (кнопки действий); слот в ветке singleItem — решим в F3/F4 по скрину 01

### F3 — карточки повтора: счётчики и localStorage (ТЗ Шаги 9–10)
- [x] RED 2026-07-21: `test/integration/shop/quick_repeat_counters_test.rb` — 5 тестов (отдельный ключ `coffeeos_shop_frequent_qty_v1` + read/writeFrequentQty в `shopFrequentCache.js` · store `frequentQuantities` + `setFrequentQty` с мгновенным `writeFrequentQty` и `Math.max(1,` + восстановление через `readFrequentQty` при init + лимит ≤120 строк · `RepeatSection` на store вместо `let quantities = $state` · фиксация клика каталога → Product · mirror clamp-логики). Прогон: **5 runs / 3 failures** (qty-персиста нет — намеренный RED `[TDD]`; фиксации Product-клика и mirror зелёные сразу). Решение: «клик по карточке категории → сразу в корзину с дефолтами» (ТЗ Шаг 9) противоречит Шагу 12 (клик → модалка модификаторов) — оставляем канон перехода в Product, вопрос заказчику
- [ ] GREEN: qty-хранилище в `shopFrequentCache.js` + store в `frequentRepeatStore.js` (≤ 120 строк) + `RepeatSection.svelte` на store

### F4 — действия «повторить в 1 клик» / «+ещё» / кастомизация (ТЗ Шаги 11–12, скрин 06)
- [ ] RED: «повторить в 1 клик» → все позиции повтора в корзину с сохранёнными `modifier_options` → hidden + success-тост; «+ещё» → expanded; ошибка → error-тост без смены состояния; кастомизация — существующий флоу `Product.svelte` (`cart_line`/модификаторы) — фиксация перехода
- [ ] GREEN: реализация в store + `RepeatSection.svelte`

### F5 — «полатить в 1 клик» на карточке повтора (скрин 06) — **SCOPE-ВОПРОС**
- [ ] В 12 шагах ТЗ нет, на скрине 6 есть (кнопка под каждой карточкой). Существует `POST /shop/api/payments/one_click`. Предложение: отдельным шагом после F4, по явному go владельца (оплата = hot-path)

### PHASE 3: REVIEW
- [ ] Sanity: N+1 / RLS / rubocop / eslint + svelte compile
- [ ] Регрессия зон: `bin/rails test test/integration/shop/` (таргетные списки — полный прогон зависает, ISSUES 🟡) + оплата §2.3 (тронут `OrderCreator`)
- [ ] Ops: SESSION_STATE / CHANGELOG / HANDOFF
- [ ] MCP Fly скрины по состояниям (peek/expanded/hidden + повтор) — после деплоя по go

## Вопросы владельцу (не блокируют B1–B4)

1. **F5 «полатить в 1 клик»** — делать? (скрин есть, в шагах ТЗ нет).
2. **401 → пустой массив** для гостя — принять адаптацию (иначе ломаем гостевой каталог)?
3. Секция «повторить» показывается только при наличии частых заказов? (0 заказов → шторка без секции, как сейчас).

## Заметки

- Категории «Черный / Холодные / Сезонные напитки» — demo-контент, в коде не хардкодим: берём реальные категории тенанта.
- Race condition localStorage + «Повторить» — паттерн `bumpChain` из `cartSheetStore.js`.
- Pre-existing shop fails — в ISSUES, не чинить молча.
