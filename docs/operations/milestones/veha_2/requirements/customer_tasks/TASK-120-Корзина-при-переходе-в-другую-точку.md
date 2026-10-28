# TASK_120: Корзина при переходе в другую точку

**ID заказчика:** TASK_120 · **CBR:** #120 · **Дата intake:** 2026-10-28 (шаг 5 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec (v3, 2026-10-25)  
**Артефакты:** нет (заказчик не прислал)  
**Google Doc:** https://docs.google.com/document/d/1Uz11weI_haC7SRlIdKt1teEloqz3QID_iWknF4609dM/edit  
**Статус:** intake 2026-10-28 · без миграции (по тексту документа)

---

## Текст задачи (дословно) — Google Doc Spec

TASK_120: Корзина при переходе в другую точку

**Тип:** новая задача (сценарий нигде не зафиксирован)
**Версия:** v3 (2026-10-25)
Бизнес-цель: при переходе в другую точку (ссылка из SMS, выбор точки, автоматический переход при старте) гость не получает чужих позиций, корзина не «застревает» и не ломает добавление и оформление заказа.

### 1. Карта интеграций — затронуто / нет
Затронуто: корзина в серверной сессии (":shop_cart", "app/services/shop/cart_service.rb:7,19"); "app/controllers/shop/api/cart_controller.rb"; локальный кэш корзины ("coffeeos_shop_cart_v1", "app/frontend/lib/shopCartCache.js:7"); "cartSheetStore.js"; "shopTenantHeader.js" ("navigateToTenant", "bootstrapShopTenant"); тесты.
Не затронуто: цены, настройки товаров по точкам и бизнес-логика корзины; checkout и платежи; Quick Repeat и повтор из истории (контракт "historyRepeatAdapter", задача TASK-HISTORY-REPEAT-PRICE-CHECK-EXT: повтор выполняется в текущей точке без смены точки); "clearCartAfterSuccessfulPay"; авторизация и сессия клиента; конфигурация cookie.

### 2. Текущее поведение — факты аудитов
- Корзина хранится в cookie-сессии под одним ключом без разбивки по точкам ("cart_service.rb:7,19"); точка участвует только при чтении: цены и доступность берутся из настроек товара текущей точки ("cart_service.rb:137,146,257,262").
- Cookie сессии ("_coffeeos_session", 90 дней, "same_site: :lax") без параметра domain ("config/initializers/session_store.rb:4-7"): сессия и корзина привязаны к хосту; у "{slug}.{SHOP_BASE_DOMAIN}" и основного хоста они разные. Режим поддоменов работает только при заданном "SHOP_BASE_DOMAIN" ("url_builder.rb:28-32,35-48"). Параметр "?tenant_id" и заголовок "X-Shop-Tenant" приоритетнее хоста ("tenant_resolution.rb:13-18"): на одном хосте можно запросить другую точку.
- Локальный кэш общий для всех точек ("shopCartCache.js:7").
- Смена точки: "navigateToTenant" добавляет "?tenant_id=" и перезагружает страницу, корзину не очищает ("shopTenantHeader.js:141-148"); "bootstrapShopTenant" при старте переводит на выбранную точку или точку последнего заказа ("shopTenantHeader.js:175-193", "App.svelte:116").
- После перехода на том же хосте тот же товар молча пересчитывается по цене новой точки ("cart_service.rb:146,281").
- Если товара нет в новой точке: "json_lines" бросает «Товар недоступен» ("cart_service.rb:143"), сервер отвечает 404 ("cart_controller.rb:30-32", "shop_api_error_handler.rb:13,30-32"), фронт очищает только свой store и кэш, "DELETE /cart" не вызывается ("cartSheetStore.js:257-264"); старая строка остаётся в сессии, и следующие добавление и создание заказа падают ("cart_controller.rb:17", "order_creator.rb:40").
- Тестов на переход между точками нет ("cart_service_test.rb:51-59": только добавление товара без настроек точки).

### 3. Scope
Разрешено: хранить вместе с корзиной точку, в которой она создана; очищать корзину на сервере при обращении из другой точки на том же хосте; признак сброса в ответе; сообщение гостю; очистка локального кэша; "DELETE /cart" при ответе 404 «Товар недоступен»; тесты.
Запрещено: отдельные корзины по точкам; изменение цен, настроек товаров и бизнес-логики корзины; изменение checkout, платежей, Quick Repeat, "historyRepeatAdapter" и "clearCartAfterSuccessfulPay" (COMPONENT_MAP:11); изменение определения текущей точки; изменение авторизации и конфигурации cookie (domain).
Решение владельца 2026-10-24 (R9 А): при переходе в другую точку корзина очищается, гость видит сообщение «Корзина очищена: вы перешли в другую точку».

### 4. Gherkin
- [ ] Subtask 1: Given корзина создана в точке B, When любой запрос корзины приходит из точки A на том же хосте (после перехода любым способом, в том числе по ссылке из SMS), Then корзина очищается на сервере, And ответ содержит признак сброса.
- [ ] Subtask 2: Given получен признак сброса, Then фронт очищает локальный кэш и store корзины и показывает «Корзина очищена: вы перешли в другую точку».
- [ ] Subtask 3: Given корзина пуста, When гость переходит в другую точку, Then сообщения нет.
- [ ] Subtask 4: Given корзина в той же точке, Then поведение прежнее, сброса нет.
- [ ] Subtask 5: Given ответ 404 «Товар недоступен» при работе с корзиной, Then вызывается очистка корзины на сервере вместе с локальной; гость может добавлять товары и оформлять заказ.
- [ ] Subtask 6: Given автоматический переход при старте ("bootstrapShopTenant"), Then применяется то же правило; запросы корзины не падают из-за позиций прежней точки.
- [ ] Subtask 7: Given старые сессии без метки точки, Then корзина обрабатывается как прежде, сбрасывается только при реальной несовместимости (404 «Товар недоступен», Subtask 5).
- [ ] Subtask 8: Given переход между хостами (поддомен точки и основной хост), Then корзина другого хоста не переносится и не очищается: сессии хостов раздельны; поведение внутри хоста определяют Subtask 1–7.
- [ ] Subtask 9: Given регрессия, Then цены, добавление, "clearCartAfterSuccessfulPay", повтор из истории (TASK_94), Quick Repeat и checkout не изменены.

### 5. TDD-проверка
Обязательные тесты: переход между точками на одном хосте с одинаковыми и разными товарами; пустая корзина; 404 «Товар недоступен» и последующее добавление; метка точки; заголовок или параметр другой точки на том же хосте; регрессия "cart_service_test.rb" и существующих тестов повтора из истории и checkout; frontend: сообщение и очистка кэша.
Команды определить по структуре тестов при сборке.
Статус: документ готов к Build.

---

## Заметки агента

- Шаг 5 очереди. Метка `TASK-SHOP-CART-ON-TENANT-SWITCH` = TASK_120 (буква F); `TASK-HISTORY-REPEAT-PRICE-CHECK-EXT` = TASK_121 (буква G, шаг 12 очереди).
- Сверка шапки с очередью (п. 4): «Зависит от» и «Порядок сборки» в документе нет; «Статус: документ готов к Build» совпадает со строкой очереди (доп. задача, без зависимостей). Расхождений нет.
- Связь в очереди: от TASK_120 зависят шаг 14 (TASK_117) и шаг 15 (TASK_118).
- Зона карты компонентов: `cartSheetStore.js` и «COMPONENT_MAP:11» — зона CartSheet → на `/spec` читать `session/COMPONENT_MAP.md`, на `/review` — решение по карте.
- Миграции в тексте нет: метка точки хранится вместе с корзиной в сессии (раздел 3).
- Факты документа (файл:строка) на intake не сверялись — это `/spec`. Пути без каталога: `tenant_resolution.rb`, вероятно, `app/controllers/shop/concerns/tenant_resolution.rb` (как в TASK_115) — проверить на `/spec`.
- `/spec` 2026-10-28: поведение кода совпало с разделом 2. Сдвиги номеров строк: `cart_service.rb` — «Товар недоступен» `:144` (в документе `:143`); `shopTenantHeader.js` — `navigateToTenant` `:148-156` (в документе `:141-148`), переходы в `bootstrapShopTenant` `:193-202` (в документе `:175-193`), сместил флаг TASK_112; вызов `bootstrapShopTenant` — `App.svelte:117` (в документе `:116`). Пути: `tenant_resolution.rb` = `app/controllers/shop/concerns/tenant_resolution.rb`, `shop_api_error_handler.rb` = `config/initializers/shop_api_error_handler.rb`.
- Выбор при сборке: метка точки — отдельный ключ сессии `:shop_cart_tenant_id` рядом с `:shop_cart`; сброс — при создании `Shop::CartService`, поэтому правило действует и при создании заказа (корзина чужой точки → «Корзина пуста», код checkout не меняется). Подробно — `session/todo.md`.

---

## Патч 1: 2026-10-28

Основание: приёмка Fly v517 ([MCP_RESULT](../../artifacts/mcp/fly_v517_2026-10-28/MCP_RESULT.md) FAIL 2, `after/results_task120_kitchen.json`) + аудит от 2026-10-28 (код и гем `rack-session` 2.1.2 из `Gemfile.lock:252`, без правок кода) · ISSUES 🔴 «TASK_120 на проде: сброс корзины затирается параллельными запросами» · способ исправления — решение владельца 2026-10-28.

**Тип:** ПАТЧ — сценарии Subtask 1, 4, 6 есть в Gherkin, на проде код их не держит. Первый патч документа.

### Аудит

| Пункт | Факт | Файл:строка |
|---|---|---|
| Хранилище сессии | `cookie_store`, `expire_after: 90.days`, без domain — вся сессия (корзина, метка, вход гостя, OTP) в одной cookie `_coffeeos_session` | `config/initializers/session_store.rb:4-7` |
| Когда пишется cookie | `commit_session?`: при `expire_after` и непустой сессии (`forced_session_update?`) cookie переписывается **на каждом ответе**, даже если запрос сессию не менял; выключает только `options[:skip]` | `rack-session-2.1.2/lib/rack/session/abstract/id.rb:350-368` |
| Shop API не управляет записью | `Shop::Api::BaseController` — только `skip_forgery_protection` и `with_shop_tenant!`, `session_options` не трогает | `app/controllers/shop/api/base_controller.rb:5-12` |
| Сброс корзины | меняет сессию только экземпляр `CartService`, увидевший метку другой точки | `app/services/shop/cart_service.rb:18-25,180-187` |
| Параллельные запросы при загрузке | в B за 14:26:56–57 параллельно ушли `/cart` ×2, `/orders/active`, `/categories`, `/frequent_products` ×3, `/config`, `/tenants` ×2, `/profile` — все со старой cookie (корзина A + метка A); оба `/cart` вернули `cart_reset: true` | `after/results_task120_kitchen.json:360-438,47-59` |
| Опрос в фоне | `/orders/active` и каталог (`/categories`, `/frequent_products`) — раз в 8 с: гонка не только при загрузке, но и между любым изменением корзины и следующим опросом | `app/frontend/lib/orderStatusSheet.js:23,46-52`, `app/frontend/lib/stores/catalog.js:11,102` |
| Симптом 1 | повторный заход в B — снова `cart_reset: true` и баннер; возврат в A — корзина A (1 шт.) вернулась, «добавить» → 2 шт., 20 ₽ | `results_task120_kitchen.json:80-94,112-127,177` |
| Симптом 2 | в другом прогоне корзина A опустела без `cart_reset` — ответ опроса со снимком до добавления пришёл после `POST /cart/add` | MCP_RESULT, строка TASK_120 |
| Кто ещё пишет сессию в shop API | корзина (`CartService`), вход гостя (`Shop::CustomerSession`), OTP по звонку (`Shop::PhoneOtp`), step-up привязки карты (`Payments::BindingStepUp`), id сессии (`request.session.id` в `profile`/`email_otp`) — все эти записи должны по-прежнему уходить в cookie | `app/services/shop/customer_session.rb:22-45`, `app/services/shop/phone_otp.rb:22,49,83-94`, `app/services/payments/binding_step_up.rb:39-54`, `app/controllers/shop/api/profile_controller.rb:34`, `email_otp_controller.rb:19,43` |
| HTML витрины | `GET /shop` → `Shop::PagesController#home` (не `Shop::Api::BaseController`) — грузится до запросов API и продолжает продлевать cookie на 90 дней | `config/routes.rb:184-187` |
| Тесты | интеграционные тесты шлют запросы последовательно с одной cookie — подмены старого снимка нет | `test/integration/shop/api/cart_tenant_switch_test.rb` (поиск `stale`/`Set-Cookie` — 0) |

### Расхождение

- Subtask 1: Given/When/Then было «корзина очищается на сервере» / по факту сброс пишется в cookie одним ответом, а ответы параллельных запросов со старым снимком (`id.rb:363-364`) переписывают cookie обратно (`results_task120_kitchen.json:80-127`) / расхождение: очистка не держится — корзина A возвращается, баннер повторяется.
- Subtask 4: Given/When/Then было «в той же точке поведение прежнее» / по факту добавление в A теряется, если ответ опроса со снимком до добавления приходит позже (`orderStatusSheet.js:23`, `catalog.js:11`) / расхождение: корзина пропадает без `cart_reset` (баг cookie-сессии был и до TASK_120, на приёмке проявился).
- Subtask 6: Given/When/Then было «запросы корзины не падают из-за позиций прежней точки» / по факту позиции прежней точки возвращаются в cookie после сброса / расхождение: правило не держится после загрузки страницы.

### Решение владельца (2026-10-28)

Запросы `/shop/api/*`, которые не изменили сессию, **не переписывают** cookie (`request.session_options[:skip] = true`). `session_store.rb` не меняется; cookie продлевается на 90 дней загрузкой `/shop` и любым запросом, изменившим сессию. Отклонено: порядок запросов на фронте (не лечит опрос раз в 8 с); перенос сессии/корзины на сервер (миграция, затрагивает вход всех панелей — отдельная задача).

### Исправленный сценарий

- [ ] Subtask 1 (patch v1): Given корзина точки A с меткой A и cookie-снимок S0, When после сброса корзины в B (`GET /cart?tenant_id=B` → `cart_reset: true`) приходит запрос shop API, не меняющий сессию, со старой cookie S0 (`/config`, `/tenants`, `/categories`, `/frequent_products`, `/orders/active`, `/profile`), Then в его ответе нет `Set-Cookie: _coffeeos_session`, And в cookie остаётся пустая корзина без метки, And повторный `GET /cart?tenant_id=B` — без `cart_reset`, And `GET /cart?tenant_id=A` — пустая корзина без `cart_reset`.
- [ ] Subtask 1a (patch v1): Given параллельно два `GET /cart?tenant_id=B` с S0, Then оба ответа с `cart_reset: true` пишут одинаковую сессию (пустая корзина, метки нет) — итог не зависит от порядка ответов.
- [ ] Subtask 4 (patch v1): Given в A после `POST /cart/add` cookie = S1 (товар есть), When приходит ответ запроса, не меняющего сессию, начатого со снимком S0 (до добавления), — в том числе `GET /cart?tenant_id=A` без изменений, Then `Set-Cookie` нет, And товар в корзине остаётся.
- [ ] Subtask 6 (patch v1): Given опрос `/orders/active` и каталога раз в 8 с, Then эти запросы cookie не переписывают (сессию не меняют).
- [ ] Subtask 10 (patch v1, охранный): Given запрос shop API, изменивший сессию (`POST /cart/add`, `PATCH`/`DELETE` строки, `DELETE /cart`, сброс в `GET /cart`, вход гостя по OTP, `Shop::PhoneOtp`, `Payments::BindingStepUp`, первая выдача id сессии), Then `Set-Cookie: _coffeeos_session` есть, как раньше.
- [ ] Subtask 11 (patch v1, охранный): Given `GET /shop` (HTML), Then `Set-Cookie` с `expires` ≈ сейчас + 90 дней, как раньше (продление сессии гостя не потеряно).
- [ ] Subtask 12 (patch v1, охранный): Given ошибка в экшене shop API (404/422/500 через `Shop::Api::ErrorHandler`), Then решение о записи cookie принимается так же (не изменилась → не пишем); запрос, изменивший сессию до ошибки (например, сброс по переполнению в `handle_cart_overflow!`), — пишет.
- [ ] Subtask 9 (patch v1): регрессия Subtask 1–9 исходного документа + `cart_persistence_test.rb` (корзина живёт между запросами), вход гостя и OTP, оплата — без изменений.

Известный предел (не чиним в патче): два **изменяющих** сессию запроса одновременно (двойное добавление, две вкладки разных точек) — по-прежнему побеждает последний ответ; это свойство cookie-сессии, лечится только переносом сессии на сервер.

### Не трогать

См. COMPONENT_MAP.md строка `cartSheetStore` (`app/frontend/lib/cartSheetStore.js`): баннер `CART_TENANT_RESET_MESSAGE`, `DELETE /cart` при «Товар недоступен», `clearCartAfterSuccessfulPay` — фронт в патче не меняется. `Shop::Api::BaseController` в карте нет (карта — UI витрины).

### Scope

Разрешено: `app/controllers/shop/api/base_controller.rb` (или concern в `app/controllers/shop/concerns/`, подключаемый только в `Shop::Api::BaseController`) — сравнить снимок сессии до и после экшена, не изменилась → `request.session_options[:skip] = true`; решение принимать в `ensure`, чтобы работало и при ответах через `rescue_from`; тесты (интеграционные с подменой cookie на старый снимок и проверкой `Set-Cookie`).
Запрещено: `config/initializers/session_store.rb` (store, `expire_after`, domain); `Shop::PagesController` и все контроллеры вне `/shop/api/*` (панели персонала, `auth`, `blog`); логика `CartService` / `CartController` и фронт (`cartSheetStore.js`, `shopCartAdd.js`) — только если тест покажет, что без этого нельзя; перенос сессии/корзины в БД или кэш; всё из «Запрещено» исходного раздела 3.

### TDD-проверка

- Новый `test/integration/shop/api/session_stale_snapshot_test.rb` — Subtask 1, 1a, 4, 6, 10, 11, 12 (старый снимок воспроизводится последовательно: сохранить значение cookie → сброс/добавление → запрос с подменённой старой cookie → нет `Set-Cookie`, состояние корзины прежнее).
- Регрессия: `ruby bin/rails test test/integration/shop/api/ test/services/shop/cart_service_tenant_switch_test.rb test/services/shop/cart_service_test.rb test/services/shop/cart_service_replace_line_test.rb test/services/shop/order_creator_test.rb` · JS: `node --test test/javascript/cart_tenant_reset_test.mjs test/javascript/clear_cart_after_successful_pay_test.mjs`.
- Fly после деплоя: прогон `verify_prod.mjs` A → B → снова B → A — сброс один раз, баннер один раз, в A корзина пустая; добавление в A не пропадает за 30 с опроса.

Открытых вопросов нет — готов к билду.
