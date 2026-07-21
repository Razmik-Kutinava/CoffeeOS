# todo — Quick Repeat Bottom Sheet (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](../milestones/veha_2/requirements/customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)  
> **Скрины:** [`artifacts/quick_repeat_bottom_sheet/`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/README.md)  
> Предыдущая фича (Bottom sheet expanded grid): закрыта 2026-07-21, deploy `[ ]` по апруву.

## Текущая фаза

**PHASE 3: REVIEW `[x]` 2026-07-21 (sanity + регрессии зелёные) · следующий шаг: deploy Fly → MCP DevTools приёмка**

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
- [x] GREEN 2026-07-21: `shopFrequentCache.js` +`FREQUENT_QTY_KEY`/read/writeFrequentQty (отдельный ключ — refresh данных счётчики не затирает); `frequentRepeatStore.js` (61 строка ≤ 120) — store `frequentQuantities` + `setFrequentQty` (clamp `Math.max(1,`, синхронный `writeFrequentQty` на каждое изменение) + восстановление qty в `initFrequentFromCache`; `RepeatSection.svelte` — bump через `setFrequentQty`, локальное зеркало `storeQty` только из подписки на store. Тесты F1–F3 **13 runs / 116 assertions / 0 failures**; регрессия шторки+каталог (heights canon, b113, checkout UX, catalog hidden card) **27 runs / 265 assertions / 0 failures**; esbuild + svelte compile OK

### F4 — действия «повторить в 1 клик» / «+ещё» / кастомизация (ТЗ Шаги 11–12, скрин 06)
- [x] RED 2026-07-21: `test/integration/shop/quick_repeat_actions_test.rb` — 4 теста (store: `repeatAllToCart` через канонный `addToCart` с `modifier_options.selected_modifiers` + qty из frequentQuantities, успех → `MODE_HIDDEN`, `repeatMore` → `MODE_EXPANDED`, тосты через `repeatFeedback`, лимит ≤120 строк · RepeatSection: оранжевая `shop-repeat-one-click` «повторить в 1 клик» + `shop-repeat-more` «+ещё» + `shop-repeat-toast` · фиксация кастомизации `Product.svelte` cart_line/initSelectedFromCartLine · mirror: success → hidden+success, error → режим не меняется, more → expanded). Прогон: **4 runs / 2 failures** (нет действий в store и кнопок в секции — намеренный RED `[TDD]`; фиксация Product и mirror зелёные сразу)
- [x] GREEN 2026-07-21: `frequentRepeatStore.js` (101 строка ≤ 120) — `repeatFeedback` store, `frequentCardKey` (общий формат ключа), `repeatAllToCart` (последовательный `addToCart` с `modifier_options.selected_modifiers` + qty из счётчиков → успех `MODE_HIDDEN` + success-тост, ошибка → error-тост без смены режима), `repeatMore` → `MODE_EXPANDED`; `RepeatSection.svelte` (134 строки — warning-зона 121–200, одна ответственность) — тост `shop-repeat-toast` с автоскрытием 2.5с, оранжевая `shop-repeat-one-click` (busy-guard от даблкликов) + `shop-repeat-more`. Тесты F1–F4 **17 runs / 166 assertions / 0 failures**; регрессия шторки+каталог **27 runs / 265 assertions / 0 failures**; esbuild + svelte compile OK. Нюанс: `addToCart` диспатчит `shop:cart-added` → PEEK, но `repeatAllToCart` ставит HIDDEN после всех добавлений — порядок корректный

### F5 — «оплатить в 1 клик» на секции повтора (скрин 06) — go владельца 2026-07-21
- Решение по scope: кнопка = repeatAllToCart → флаг `shop_repeat_autopay` в sessionStorage → `push("/checkout")` → Checkout снимает флаг и автооткрывает шит оплаты (existing `openPaymentSheet` с преселектом primary-карты). **Само списание — существующий канон one_click с подтверждением «Оплатить»**: молча деньги не снимаем (безопасность), бэкенд-оплату не трогаем. Ошибка добавления → error-тост F4, навигации нет
- [x] RED 2026-07-21: `test/integration/shop/quick_repeat_pay_one_click_test.rb` — 4 теста (store: `repeatPayOneClick` через `repeatAllToCart()` + `REPEAT_AUTOPAY_KEY` + push("/checkout"), лимит ≤120 · секция: `shop-repeat-pay-one-click` «оплатить в 1 клик» · Checkout: consume флага + removeItem · mirror: success → checkout+autopay, error → stay). Прогон: **4 runs / 3 failures** (флоу нет — намеренный RED `[TDD]`; mirror зелёный сразу)
- [x] GREEN 2026-07-21: `frequentRepeatStore.js` (119 строк ≤ 120, сжаты комментарии) — `REPEAT_AUTOPAY_KEY` + `repeatPayOneClick` (`repeatAllToCart()` → sessionStorage-флаг → `push("/checkout")`, при ошибке добавления навигации нет); `RepeatSection.svelte` — кнопка `shop-repeat-pay-one-click` «оплатить в 1 клик» (outline-оранж, общий busy-guard); `Checkout.svelte` — в onMount consume флага → `openPaymentSheet()` (existing канон Шага 3/4: преселект primary-карты, подтверждение «Оплатить»). Тесты: F1–F5 **21 runs / 192 assertions / 0 failures**; регрессия оплаты §2.3 + one_click step4 **29 runs / 0 failures (2 pre-existing skips)**; шторка+каталог **27 runs / 0 failures**; svelte compile (RepeatSection, Checkout) + esbuild OK. Найден pre-existing конфликт `checkout_ui_cleanup_test.rb` vs канон «оплата через шторку» (падает и на чистом HEAD, проверено git stash) → 🟡 ISSUES

### PHASE 3: REVIEW
- [x] Sanity 2026-07-21: rubocop 12 файлов фичи — 0 offenses · N+1 нет (4 плоских pluck + index_by, фронт без запросов в циклах) · RLS: 123/0 (services + frequent_products API + tenant_isolation + rls_tenant_isolation) · svelte compile + esbuild OK
- [x] Регрессия зон 2026-07-21: оплата §2.3 + one_click step4 **29/0 (2 pre-existing skips)** · шторка+каталог **27/0** · фича F1–F5 **21/0**
- [x] Ops: SESSION_STATE / CHANGELOG / HANDOFF обновлены
- [ ] Deploy Fly (апрув дан) → MCP DevTools скрины по состояниям (peek/expanded/hidden + повтор + оплата)

## Вопросы владельцу (не блокируют B1–B4)

1. **F5 «полатить в 1 клик»** — делать? (скрин есть, в шагах ТЗ нет).
2. **401 → пустой массив** для гостя — принять адаптацию (иначе ломаем гостевой каталог)?
3. Секция «повторить» показывается только при наличии частых заказов? (0 заказов → шторка без секции, как сейчас).

## Заметки

- Категории «Черный / Холодные / Сезонные напитки» — demo-контент, в коде не хардкодим: берём реальные категории тенанта.
- Race condition localStorage + «Повторить» — паттерн `bumpChain` из `cartSheetStore.js`.
- Pre-existing shop fails — в ISSUES, не чинить молча.
