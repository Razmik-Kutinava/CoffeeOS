# Исправление открытия /shop во встроенных браузерах Telegram и Instagram

**Дата интейка:** 2026-08-14
**Источник:** текст заказчика (передан владельцем в чат)
**CBR:** #64
**Артефакты:** docs/operations/milestones/veha_2/artifacts/shop_telegram_instagram_inapp_browser/

---

## Текст заказчика (дословно)

SPEC-TASK-[НОМЕР]: Исправление открытия /shop во встроенных браузерах Telegram и Instagram
Бизнес-цель: обеспечить стабильное открытие публичной витрины /shop?tenant_id=<UUID> внутри встроенных браузеров Telegram и Instagram на Android/iOS без необходимости копировать ссылку в Chrome/Safari. При этом приложение не должно зависать на первоначальном shop-boot-skeleton при ошибке JavaScript bootstrap, API, storage или другого runtime-компонента.
Ключевой принцип задачи: не предполагать заранее, что причиной является Telegram, Instagram, CORS, cookies, tenant_id, Fly.dev, localStorage или API. Сначала установить фактическую точку отказа в цепочке:
HTML → JS bootstrap → Svelte mount → router → tenant_id → API → JSON parsing → state update → render
После этого исправить конкретную первопричину. Telegram и Instagram не должны получать отдельные костыльные ветки без доказанной технической необходимости.
1. Связь с картой интеграций
Затронутые сервисы из @INTEGRATIONS.md:
Telegram In-App Browser / WebView
Instagram In-App Browser
Тип связки: внешний источник перехода пользователя в публичную витрину CoffeeOS через embedded browser.
Изменение внешних API-контрактов: не требуется. Задача изменяет только устойчивость нашей страницы /shop к средам Telegram/Instagram.
Точки входа нашей системы:
GET /shop?tenant_id=<UUID>
GET /shop/api/categories?tenant_id=<UUID>
Identity Mapping:
tenant_id из query-параметра /shop?tenant_id=<UUID> → внутренний tenant CoffeeOS.
Telegram/Instagram user_id, username, phone и другие внешние идентификаторы не маппятся на внутренний user_id в рамках этой задачи.
User-Agent и факт нахождения пользователя внутри Telegram/Instagram не являются механизмом авторизации.
Смежные модули, которые НЕЛЬЗЯ ломать: обычное открытие /shop в Chrome/Safari, catalog API, tenant_id resolution, cart/cart sheet, catalog polling, Rails session/CSRF и существующая frontend-навигация.
2. Разрешенный и Запрещенный Scope
Разрешено менять/создавать
app/frontend/routes/Catalog.svelte
app/frontend/lib/stores/catalog.js
app/frontend/lib/shopLocalStorage.js
app/frontend/lib/api.js
app/frontend/lib/cartSheetStore.js — только если диагностика подтвердит связь с причиной
фактический JS entrypoint (application.js / application.ts или аналог)
Svelte router / route /shop — только при подтвержденной проблеме
app/views/shop/pages/home.html.erb
app/views/layouts/shop.html.erb
app/controllers/shop/pages_controller.rb — только при подтвержденной серверной причине
app/controllers/shop/api/categories_controller.rb — только при подтвержденной причине API
Rails routes и связанные /shop настройки — только при подтвержденной необходимости
Vite-конфигурацию — только при подтвержденной проблеме assets/chunks
fly.toml — только если диагностика подтвердит cold start как фактическую причину
тесты, непосредственно относящиеся к /shop, bootstrap, catalog API, storage и embedded browser compatibility
INTEGRATIONS.md — только для внесения описанных в разделе 6 изменений связки
Строго запрещено менять
app/modules/auth/* и глобальную авторизацию без доказанной связи
глобальную CSRF-защиту Rails
глобальные CORS/security-настройки без доказанной причины
платежи, автоплатежи, SMS/Callcheck и другие несвязанные интеграции
бизнес-логику заказов, истории заказов и начислений
публичные контракты несвязанных API
принудительный redirect Telegram/Instagram → Chrome/Safari как основной fix
Telegram-specific или Instagram-specific browser detection без доказанной необходимости
добавление Telegram/Instagram credentials, токенов или user identity в frontend
изменение логики tenant resolution только ради обхода WebView
3. Сценарии и Чек-лист (Gherkin)
A. Воспроизведение и определение точки отказа
Subtask 1: Воспроизвести /shop в Chrome Desktop
Given: существует URL /shop?tenant_id=<UUID>
When: открыть URL в Chrome Desktop
Then: зафиксировать эталонное поведение: HTML загружается, JS bootstrap выполняется, Svelte монтируется, каталог отображается
Subtask 2: Воспроизвести /shop в мобильном Chrome/Safari
Given: используется тот же URL
When: открыть его в Chrome Android и Safari iOS
Then: зафиксировать эталонное мобильное поведение для сравнения с embedded browsers
Subtask 3: Воспроизвести /shop в Telegram Android
Given: пользователь получает ссылку внутри Telegram
When: открыть ссылку тапом во встроенном браузере Telegram Android
Then: зафиксировать точный результат: открытие, белый экран, первоначальный skeleton, бесконечная загрузка, JS error или API error
Subtask 4: Воспроизвести /shop в Telegram iOS
Given: пользователь получает тот же URL внутри Telegram
When: открыть ссылку во встроенном браузере Telegram iOS
Then: зафиксировать точный результат и сравнить с Telegram Android
Subtask 5: Воспроизвести /shop в Instagram Android
Given: пользователь открывает тот же URL из Instagram
When: ссылка открывается в Instagram In-App Browser Android
Then: зафиксировать точный результат и сравнить с Chrome/Telegram
Subtask 6: Воспроизвести /shop в Instagram iOS
Given: пользователь открывает тот же URL из Instagram
When: ссылка открывается в Instagram In-App Browser iOS
Then: зафиксировать точный результат и сравнить с Chrome/Telegram
Subtask 7: Определить общий или специфичный характер проблемы
Given: доступны результаты Telegram Android/iOS и Instagram Android/iOS
When: сравнить точки отказа
Then: определить, является ли проблема общей для embedded browsers либо существует отдельная причина для конкретной платформы/приложения
B. Bootstrap и Svelte
Subtask 8: Найти фактический JavaScript entrypoint
Given: /shop подключает frontend через Rails/Vite
When: проследить vite_javascript_tag и фактический entrypoint
Then: определить цепочку application entrypoint → Svelte initialization → router → /shop → Catalog.svelte
Subtask 9: Проверить выполнение JS bootstrap
Given: первоначальный HTML содержит shop-boot-skeleton
When: открыть /shop в Telegram и Instagram
Then: определить, выполняется ли application entrypoint; если нет, зафиксировать конкретный failed resource/runtime error
Subtask 10: Проверить Svelte mount
Given: JS entrypoint успешно загрузился
When: приложение запускается
Then: Catalog.svelte должен быть смонтирован и первоначальный skeleton должен быть заменен приложением
Subtask 11: Проверить router
Given: используется svelte-spa-router
When: /shop открывается напрямую внутри embedded browser
Then: router должен корректно определить route без предварительной навигации
Subtask 12: Зафиксировать runtime errors
Given: bootstrap может завершиться до Catalog
When: выполнить диагностику WebView через chrome://inspect, Safari Web Inspector, Eruda или эквивалентный временный механизм
Then: зафиксировать конкретные TypeError, ReferenceError, SyntaxError, SecurityError, NetworkError и другие ошибки, если они присутствуют
C. JS assets и static resources
Subtask 13: Проверить загрузку application bundle
Given: /shop зависит от frontend bundle
When: сравнить Network Chrome, Telegram и Instagram
Then: application JS должен успешно загрузиться во всех поддерживаемых окружениях
Subtask 14: Проверить dynamic chunks
Given: frontend может использовать Vite chunks/dynamic imports
When: открыть /shop в embedded browsers
Then: ни один необходимый chunk не должен получать ошибку загрузки, неправильный MIME type, redirect или блокировку
Subtask 15: Проверить CSS и прочие ресурсы
Given: приложение зависит от CSS/fonts/images
When: сравнить Network
Then: выявить и исправить только фактически влияющие на bootstrap ошибки ресурсов
Subtask 16: Проверить CSP и cache для assets
Given: production использует security headers/cache
When: сравнить Chrome, Telegram и Instagram
Then: установить, блокирует ли CSP/cache загрузку необходимых ресурсов; не ослаблять CSP без доказательства
D. tenant_id, routing и redirects
Subtask 17: Проверить window.location
Given: URL содержит tenant_id=<UUID>
When: приложение запускается в Telegram/Instagram
Then: window.location.href, window.location.search и извлеченный tenant_id соответствуют исходной ссылке
Subtask 18: Проверить Rails tenant resolution
Given: /shop получает tenant_id
When: запрос приходит из Telegram/Instagram
Then: Rails получает корректный tenant и не теряет параметр
Subtask 19: Проверить redirect chain
Given: embedded browsers могут иначе обрабатывать цепочку переходов
When: открыть исходный /shop
Then: отсутствуют лишние http→https, www→non-www или иные промежуточные redirects, способные привести к потере query-параметров или обрыву загрузки
E. Catalog API
Subtask 20: Проверить API-запрос в Telegram
Given: Catalog.svelte успешно смонтирован
When: выполняется GET /shop/api/categories?tenant_id=<UUID>
Then: определить фактический request/response, status, headers и body
Subtask 21: Проверить API-запрос в Instagram
Given: Catalog.svelte успешно смонтирован
When: выполняется тот же запрос
Then: определить фактический request/response, status, headers и body в Instagram Android/iOS
Subtask 22: Разделить API failure и frontend failure
Given: пользователь видит skeleton/loading
When: сравнить lifecycle и Network
Then: определить, происходит ли request не отправлен → server error → 200 but parsing/state failure; исправление выбирать только после установления конкретного варианта
Subtask 23: Проверить JSON parsing
Given: API возвращает response
When: frontend обрабатывает response
Then: JSON должен корректно распарситься и привести к обновлению состояния каталога
F. Cookies / CSRF / Security
Subtask 24: Проверить cookies
Given: api.js использует credentials: "same-origin"
When: выполняется первый запрос каталога в Telegram/Instagram
Then: определить, доступны ли необходимые cookies/session и отличаются ли правила embedded browser
Subtask 25: Проверить CSRF
Given: api.js передает X-CSRF-Token
When: выполняется API request
Then: подтвердить или исключить влияние CSRF; не отключать глобальную CSRF-защиту
Subtask 26: Проверить CORS
Given: frontend/API находятся на coffeeos.fly.dev
When: сравнить фактические request origin и response
Then: не добавлять CORS «на всякий случай»; изменить его только при доказанной необходимости
Subtask 27: Проверить security headers
Given: приложение использует production security headers
When: сравнить Chrome, Telegram и Instagram
Then: проверить CSP, X-Frame-Options, Cross-Origin headers и Referrer-Policy на фактическую блокировку
G. localStorage и frontend resilience
Subtask 28: Проверить shopLocalStorage.js
Given: embedded WebView может ограничивать storage
When: выполнить getItem/setItem через существующий storage abstraction
Then: выявить фактические SecurityError/storage failures и их влияние на bootstrap
Subtask 29: Сделать readShopLocalStorage() безопасным
Given: storage недоступен или выбрасывает exception
When: frontend пытается прочитать cache
Then: возвращается безопасный fallback, а приложение продолжает работу
Subtask 30: Сделать writeShopLocalStorage() безопасным
Given: storage недоступен
When: frontend сохраняет каталог
Then: ошибка storage не ломает каталог и не превращается в unhandled rejection
Subtask 31: Защитить loadCatalog()
Given: API error и/или storage error происходят одновременно
When: выполняется fallback
Then: readCatalogCache()/writeCatalogCache() не могут самостоятельно уронить loadCatalog() и оставить UI в некорректном состоянии
Subtask 32: Проверить refreshCartSheet()
Given: refreshCartSheet().catch(() => {}) вызывается при mount
When: Catalog запускается в embedded browser
Then: import-time/synchronous ошибка не должна блокировать mount или загрузку каталога
Subtask 33: Проверить browser APIs и зависимости
Given: Telegram/Instagram используют embedded browser
When: проанализировать реально выполняемый код
Then: исправить только подтвержденную несовместимость browser API или сторонней библиотеки
H. Polling
Subtask 34: Проверить запуск catalog polling
Given: polling запускается после успешной загрузки
When: каталог работает в Telegram/Instagram
Then: polling не запускается раньше времени и не мешает первичной загрузке
Subtask 35: Проверить visibilitychange
Given: embedded browsers могут менять visibility state
When: пользователь переключается между приложением и WebView
Then: polling не создает бесконечные запросы, reset состояния или ошибки каталога
I. Error UX
Subtask 36: Исключить вечный shop-boot-skeleton
Given: bootstrap завершается ошибкой
When: приложение не может смонтироваться
Then: пользователь не остается навсегда на Загрузка меню…; должен существовать контролируемый error fallback
Subtask 37: Обработать API error
Given: API возвращает 4xx/5xx или network error
When: loadCatalog() завершается
Then: loading=false, показывается понятное сообщение Не удалось загрузить меню и кнопка Повторить
Subtask 38: Обработать недоступный cache
Given: API недоступен и cache отсутствует/поврежден
When: выполняется fallback
Then: отображается понятная ошибка, а не бесконечный skeleton
Subtask 39: Сохранить cache fallback
Given: API недоступен, но cache валиден
When: выполняется loadCatalog()
Then: последнее сохраненное меню может быть показано пользователю
J. Тесты
Subtask 40: Добавить тест корректного tenant_id
Given: /shop?tenant_id=UUID
When: frontend вызывает catalog API
Then: передается правильный tenant_id
Subtask 41: Добавить тест API success
Given: API возвращает 200
When: каталог загружается
Then: категории и товары отображаются
Subtask 42: Добавить тест API error
Given: API возвращает 500/network error
When: loadCatalog() завершается
Then: loading=false и отображается error state
Subtask 43: Добавить тест storage unavailable
Given: localStorage выбрасывает exception
When: API возвращает каталог
Then: каталог успешно отображается без cache
Subtask 44: Добавить тест cache fallback
Given: API недоступен и cache содержит валидный каталог
When: loadCatalog() выполняется
Then: cache используется для отображения каталога
Subtask 45: Добавить регрессионный тест bootstrap
Given: /shop содержит первоначальный server-rendered skeleton
When: Svelte bootstrap завершается успешно
Then: skeleton заменяется приложением
K. Финальная проверка
Subtask 46: Проверить Telegram Android на реальном устройстве
Given: исправление установлено
When: открыть ссылку тапом внутри Telegram Android
Then: /shop полностью отображает меню
Subtask 47: Проверить Telegram iOS на реальном устройстве
Given: исправление установлено
When: открыть ссылку тапом внутри Telegram iOS
Then: /shop полностью отображает меню
Subtask 48: Проверить Instagram Android на реальном устройстве
Given: исправление установлено
When: открыть ссылку внутри Instagram Android
Then: /shop полностью отображает меню
Subtask 49: Проверить Instagram iOS на реальном устройстве
Given: исправление установлено
When: открыть ссылку внутри Instagram iOS
Then: /shop полностью отображает меню
Subtask 50: Проверить обычные браузеры на регрессию
Given: WebView compatibility исправлена
When: открыть /shop в Chrome Desktop, Chrome Android и Safari iOS
Then: существующее поведение не изменилось
Subtask 51: Удалить временную диагностику
Given: фактическая причина установлена
When: подготовить production build
Then: временные console.log/Eruda/debug hooks удалены или заменены контролируемым telemetry/error reporting механизмом
Subtask 52: Подготовить итоговый технический отчет
Given: все проверки завернены
When: задача передается на приемку
Then: отчет содержит Причина, Доказательство, Исправление, Проверка по всем окружениям и Регрессии
4. Команды TDD-проверки
Запуск тестов: npm test tests/integration/TASK-[НОМЕР].test.ts
Проверка типов: npx tsc --noEmit
Production build: использовать существующую команду production build проекта
Server diagnostics: fly logs
Mobile WebView diagnostics: использовать доступный remote Web Inspector / chrome://inspect / временный Eruda только для диагностики
5. Приёмка
Задача считается выполненной только если:
/shop?tenant_id=<UUID> открывается в Chrome Desktop.
/shop открывается в Chrome Android.
/shop открывается в Safari iOS.
/shop открывается внутри Telegram Android.
/shop открывается внутри Telegram iOS.
/shop открывается внутри Instagram Android.
/shop открывается внутри Instagram iOS.
Меню полностью отображается во всех четырех embedded browser окружениях.
tenant_id корректно проходит от URL до catalog API.
Первоначальный shop-boot-skeleton не остается бесконечно на экране.
Ошибка API переводит UI в понятный error state.
Недоступный localStorage не ломает страницу.
Polling не ломает первоначальную загрузку и дальнейшую работу каталога.
Chrome/Safari не имеют регрессий.
Не используется принудительный redirect из Telegram/Instagram в Chrome/Safari как основной fix.
Исправление основано на доказанной первопричине.
Добавлены тесты на найденную причину и критические fallback-сценарии.
INTEGRATIONS.md обновлен согласно разделу 6.
6. Формат технического отчета разработчика
Причина
Указать конкретную точку отказа в цепочке:
HTML → JS bootstrap → Svelte mount → router → tenant_id → API → JSON parsing → state → render.
Доказательство
Привести фактическое отличие между рабочим и нерабочим окружением.
Например:
Chrome:
GET /shop/api/categories → 200

Instagram:
GET /shop/api/categories → 403

или:
Chrome:
application.js → loaded

Telegram:
application.js → loaded
chunk X.js → failed

Исправление
Указать измененные файлы и конкретное техническое изменение.
Проверка
Указать результат отдельно для:
Chrome Desktop
Chrome Android
Safari iOS
Telegram Android
Telegram iOS
Instagram Android
Instagram iOS
Регрессии
Подтвердить, что обычное открытие /shop продолжает работать и изменения не затронули несвязанные модули.
TODO: TASK-[НОМЕР]
Subtask 1: Воспроизвести /shop в Chrome Desktop.
Subtask 2: Воспроизвести /shop в Chrome Android и Safari iOS.
Subtask 3: Воспроизвести /shop в Telegram Android.
Subtask 4: Воспроизвести /shop в Telegram iOS.
Subtask 5: Воспроизвести /shop в Instagram Android.
Subtask 6: Воспроизвести /shop в Instagram iOS.
Subtask 7: Сравнить точки отказа Telegram и Instagram.
Subtask 8: Найти фактический JS entrypoint.
Subtask 9: Проверить выполнение JavaScript bootstrap.
Subtask 10: Проверить Svelte mount.
Subtask 11: Проверить svelte-spa-router и /shop.
Subtask 12: Зафиксировать runtime JS ошибки.
Subtask 13: Проверить application bundle.
Subtask 14: Проверить dynamic JS chunks.
Subtask 15: Проверить CSS и static resources.
Subtask 16: Проверить CSP/cache для assets.
Subtask 17: Проверить window.location и tenant_id.
Subtask 18: Проверить Rails tenant resolution.
Subtask 19: Проверить redirect chain.
Subtask 20: Проверить catalog API в Telegram.
Subtask 21: Проверить catalog API в Instagram.
Subtask 22: Определить API failure или frontend failure.
Subtask 23: Проверить JSON parsing и state update.
Subtask 24: Проверить cookies и credentials: "same-origin".
Subtask 25: Проверить CSRF.
Subtask 26: Проверить CORS только на фактическую необходимость.
Subtask 27: Проверить CSP и security headers.
Subtask 28: Проверить shopLocalStorage.js.
Subtask 29: Сделать readShopLocalStorage() безопасным.
Subtask 30: Сделать writeShopLocalStorage() безопасным.
Subtask 31: Защитить cache fallback в loadCatalog().
Subtask 32: Проверить refreshCartSheet().
Subtask 33: Проверить browser APIs и сторонние зависимости.
Subtask 34: Проверить catalog polling.
Subtask 35: Проверить visibilitychange.
Subtask 36: Исключить вечный shop-boot-skeleton.
Subtask 37: Обработать API error state.
Subtask 38: Обработать отсутствие cache.
Subtask 39: Сохранить fallback на валидный cache.
Subtask 40: Добавить тест корректного tenant_id.
Subtask 41: Добавить тест успешной загрузки каталога.
Subtask 42: Добавить тест API/network error.
Subtask 43: Добавить тест недоступного localStorage.
Subtask 44: Добавить тест cache fallback.
Subtask 45: Добавить регрессионный тест bootstrap.
Subtask 46: Проверить Telegram Android на реальном устройстве.
Subtask 47: Проверить Telegram iOS на реальном устройстве.
Subtask 48: Проверить Instagram Android на реальном устройстве.
Subtask 49: Проверить Instagram iOS на реальном устройстве.
Subtask 50: Проверить Chrome Desktop, Chrome Android и Safari iOS на регрессию.
Subtask 51: Удалить временные debug logs/diagnostic hooks.
Subtask 52: Подготовить итоговый технический отчет.
Subtask 53: Обновить INTEGRATIONS.md по контракту связки Telegram/Instagram → /shop.

---

## Заметки агента

- **CBR #64.** Задачи 2–5 серии (связка / полная работа / UI / UX+perf) — отдельные диалоги, этот док только про открытие `/shop`.
- 53 subtask — диагностическая матрица, не 53 коммита. Сначала точка отказа в цепочке HTML → mount → API, потом фикс доказанной причины.
- **Стек тестов репо:** не `npm test …TASK-N.test.ts` и не `tsc`. Канон: `node --test test/javascript/*.mjs` + `bin/rails test` зоны shop.
- `shop-boot-skeleton` в `home.html.erb` = до `mount(App)`. После mount каталог показывает `PageSkeleton` / «Не удалось загрузить меню». Вечный «Загрузка меню…» = bootstrap не дошёл до mount.
- `shopLocalStorage.js` уже в try/catch; у Catalog уже есть error-state без кнопки «Повторить».
- `initTelegram()` в `App.svelte` — Mini App `WebApp.ready/expand`, не in-app browser по ссылке. Не считать причиной без доказательства.
- Приёмка hot-path: Fly **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`. TG/IG — реальные устройства.
- Запрещено: redirect «открой в Chrome» как основной fix; UA-ветки; CORS/CSRF «на всякий случай»; auth/платежи.
