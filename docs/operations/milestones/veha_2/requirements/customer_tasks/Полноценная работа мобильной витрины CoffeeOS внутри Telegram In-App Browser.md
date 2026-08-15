# Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser

**Дата интейка:** 2026-08-15
**Источник:** текст заказчика (передан владельцем в чат)
**CBR:** #66
**Артефакты:** docs/operations/milestones/veha_2/artifacts/mobile_storefront_telegram_webview/

---

## Текст заказчика (дословно)

Задача: Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser
Бизнес-цель:
Обеспечить полноценную работу мобильной витрины CoffeeOS внутри Telegram In-App Browser (WebView) без критических отличий от обычного мобильного браузера. После подтверждения технической совместимости адаптировать интерфейс и поведение витрины под ограничения Telegram WebView, сохранив авторизацию, API-взаимодействие, tenant-контекст, cookies/storage и основные пользовательские сценарии.
1. Связь с картой интеграций
Затронутые сервисы из @INTEGRATIONS.md:
Telegram In-App Browser / Telegram WebView.
Backend API CoffeeOS.
Frontend PWA / Svelte.
Cookie/session storage.
CORS/CSP infrastructure.
Новые/изменяемые интеграционные контракты: требуется зафиксировать в @INTEGRATIONS.md фактическую связку Telegram WebView → CoffeeOS Web/PWA → Backend API.
Смежные модули, которые НЕЛЬЗЯ ломать:
авторизация/идентификация пользователя;
tenant_id и tenant routing;
API-запросы витрины;
корзина и оформление заказа;
cookies/session;
localStorage/sessionStorage;
существующая мобильная версия вне Telegram;
существующие интеграции Telegram/Deep Link, если они уже используются.
2. Разрешенный и Запрещенный Scope
Разрешено менять/создавать
src/routes/** — только маршруты и страницы мобильной витрины, необходимые для WebView compatibility.
src/lib/** — только WebView detection, storage/cookie compatibility и связанные frontend utilities.
src/components/** — только компоненты витрины, требующие адаптации поведения/UX.
src/services/** — только API/fetch-слой, если требуется устранение WebView-специфичных проблем.
src/hooks/** — только WebView/browser lifecycle hooks, если используются в проекте.
tests/** — тесты TASK-048.
Конфигурацию CSP/CORS только в том месте, где она реально управляется проектом.
Backend API middleware/config только в пределах изменений, необходимых для корректной работы WebView.
Строго запрещено менять
бизнес-логику расчета заказа;
платежную бизнес-логику;
авторизацию как бизнес-механизм, если проблема не вызвана непосредственно WebView compatibility;
структуру БД и миграции без отдельной задачи;
tenant-модель и правила определения tenant;
существующие Telegram Bot flows, не связанные с открытием WebView;
desktop UI;
native Telegram Bot;
сторонние интеграции, не участвующие в работе WebView.
3. Сценарии и Чек-лист (Gherkin)
Subtask 1: Зафиксировать запуск мобильной витрины внутри Telegram WebView
Given: пользователь открывает URL мобильной витрины через Telegram.
When: Telegram запускает страницу во встроенном In-App Browser.
Then: HTML загружается без критической ошибки, JavaScript запускается, Svelte-приложение монтируется, а пользователь видит рабочую витрину.
Subtask 2: Проверить выполнение JavaScript и Svelte runtime
Given: витрина открыта внутри Telegram WebView.
When: выполняется клиентский JavaScript и происходит hydration/mount Svelte-приложения.
Then: отсутствуют WebView-specific runtime errors, приложение не остается на loading/error screen и интерактивные компоненты работают.
Subtask 3: Проверить API fetch из Telegram WebView
Given: Svelte-приложение успешно загружено.
When: frontend выполняет штатный API fetch.
Then: запрос доходит до backend, корректно обрабатывается CORS и frontend получает ожидаемый HTTP response.
Subtask 4: Проверить CORS для WebView origin
Given: API вызывается из Telegram WebView.
When: браузер выполняет cross-origin API request.
Then: preflight/основной запрос не блокируется CORS policy, если запрос разрешен текущей архитектурой приложения.
Subtask 5: Проверить CSP
Given: страница открыта внутри Telegram WebView.
When: браузер загружает JS, CSS, API resources и остальные разрешенные ресурсы.
Then: CSP не блокирует необходимые ресурсы и в консоли отсутствуют критические CSP violations, препятствующие работе приложения.
Subtask 6: Проверить cookies и session state
Given: пользователь открывает витрину внутри Telegram WebView.
When: приложение получает/использует cookies, необходимые backend session/auth flow.
Then: cookies обрабатываются ожидаемым образом, session state не теряется между последовательными API-запросами.
Subtask 7: Проверить localStorage
Given: Telegram WebView разрешает storage для текущего приложения.
When: frontend сохраняет и читает необходимые данные через localStorage.
Then: данные успешно записываются и читаются без исключений; отсутствие storage не приводит к падению приложения.
Subtask 8: Проверить sessionStorage
Given: приложение использует sessionStorage, если он предусмотрен текущей реализацией.
When: frontend записывает и читает данные текущей сессии.
Then: операции выполняются корректно либо имеют безопасный fallback без падения приложения.
Subtask 9: Проверить передачу и сохранение tenant_id
Given: витрина открыта с tenant-контекстом.
When: frontend выполняет первоначальную загрузку и последующие API-запросы.
Then: корректный tenant_id сохраняется/передается в соответствии с существующим контрактом и backend не теряет tenant context внутри Telegram WebView.
Subtask 10: Проверить отсутствие зависимости от desktop browser APIs
Given: приложение работает внутри Telegram WebView.
When: выполняются основные сценарии витрины.
Then: приложение не падает из-за отсутствующих или ограниченных browser APIs; потенциально недоступные APIs имеют безопасную проверку/fallback.
Subtask 11: Проверить основной пользовательский сценарий витрины
Given: витрина успешно открыта внутри Telegram WebView.
When: пользователь просматривает каталог, выбирает товар и выполняет основные действия с UI.
Then: интерфейс реагирует корректно, состояние Svelte обновляется, API-запросы выполняются, данные не теряются.
Subtask 12: Проверить переходы и навигацию
Given: пользователь находится внутри Telegram WebView.
When: выполняет переходы между страницами/состояниями витрины.
Then: navigation/router работает без открытия некорректных внешних окон, потери tenant context или сброса состояния, если текущий flow предполагает его сохранение.
Subtask 13: Адаптировать viewport и layout под Telegram WebView
Given: витрина открыта на мобильном устройстве в Telegram WebView.
When: пользователь взаимодействует со страницей.
Then: layout корректно учитывает доступную высоту/ширину WebView, системные области и динамическое изменение viewport без перекрытия ключевого UI.
Subtask 14: Адаптировать WebView-specific UX
Given: Telegram WebView ограничивает часть стандартного browser behavior.
When: пользователь выполняет действия, чувствительные к WebView lifecycle/navigation.
Then: интерфейс предоставляет корректное поведение/fallback вместо browser-specific сценариев, которые Telegram не поддерживает или поддерживает иначе.
Subtask 15: Обработать ошибки загрузки и API
Given: WebView теряет сеть либо API возвращает ошибку.
When: frontend выполняет API-запрос.
Then: пользователь получает понятное состояние ошибки/retry, приложение не падает и не остается в бесконечном loading.
Subtask 16: Проверить cold start
Given: пользователь впервые открывает витрину в Telegram WebView.
When: приложение загружается с нулевым frontend state.
Then: JS, Svelte, API, tenant context и необходимые storage/session механизмы инициализируются в правильном порядке.
Subtask 17: Проверить повторное открытие
Given: пользователь ранее открывал витрину в Telegram WebView.
When: он повторно открывает тот же storefront URL.
Then: приложение корректно восстанавливает допустимое состояние и не использует устаревший/чужой tenant_id или session state.
Subtask 18: Добавить regression tests для WebView compatibility
Given: реализованы WebView compatibility fixes.
When: запускается набор тестов TASK-048.
Then: тесты покрывают JS/Svelte initialization, API/fetch, tenant context, storage/cookie handling и error fallback.
4. Команды TDD-проверки
Запуск тестов: npm test tests/integration/TASK-048.test.ts
Проверка типов: npx tsc --noEmit
Дополнительно: ручная проверка на реальном мобильном устройстве через Telegram In-App Browser обязательна для финального acceptance.
5. Definition of Done
Мобильная витрина открывается непосредственно внутри Telegram WebView.
Svelte-приложение стабильно монтируется.
API/fetch работает.
CORS и CSP не блокируют необходимые запросы/ресурсы.
Cookies и storage работают либо имеют безопасный fallback.
tenant_id не теряется.
Основные пользовательские сценарии витрины работают.
WebView-specific viewport/navigation ограничения обработаны.
Ошибки сети/API не приводят к падению приложения.
Regression tests проходят.
Работа обычной мобильной витрины вне Telegram не регрессировала.

TODO:
Subtask 1: Зафиксировать запуск мобильной витрины внутри Telegram WebView
Subtask 2: Проверить выполнение JavaScript и Svelte runtime
Subtask 3: Проверить API fetch из Telegram WebView
Subtask 4: Проверить CORS для WebView origin
Subtask 5: Проверить CSP
Subtask 6: Проверить cookies и session state
Subtask 7: Проверить localStorage
Subtask 8: Проверить sessionStorage
Subtask 9: Проверить передачу и сохранение tenant_id
Subtask 10: Проверить отсутствие зависимости от desktop browser APIs
Subtask 11: Проверить основной пользовательский сценарий витрины
Subtask 12: Проверить переходы и навигацию
Subtask 13: Адаптировать viewport и layout под Telegram WebView
Subtask 14: Адаптировать WebView-specific UX
Subtask 15: Обработать ошибки загрузки и API
Subtask 16: Проверить cold start
Subtask 17: Проверить повторное открытие
Subtask 18: Добавить regression tests для WebView compatibility

INTEGRATIONS.md Update
## Изменения в связке: Telegram In-App Browser / WebView → CoffeeOS Mobile Storefront

- **Точки входа:**
  - Mobile storefront URL, открываемый пользователем внутри Telegram In-App Browser.
  - Backend API endpoints, вызываемые storefront frontend из Telegram WebView.
  - Не добавлять новые Telegram Bot API endpoints без отдельного требования.

- **Identity Mapping:**
  - Telegram WebView является runtime/container для мобильной витрины и не должен самостоятельно подменять внутреннюю идентичность пользователя.
  - `tenant_id` должен передаваться и разрешаться по существующему контракту CoffeeOS.
  - Если в существующей архитектуре Telegram user identity уже маппится на внутренний `user_id`, сохранить существующий mapping без изменения.
  - Запрещено определять `tenant_id` только на основании client-side storage, если backend уже имеет authoritative tenant context.

- **Handling Errors:**
  - Ошибка загрузки JS/Svelte не должна приводить к бесконечному loading без диагностируемого состояния.
  - Ошибка `fetch`/API должна приводить к штатному error/retry состоянию.
  - CORS/CSP блокировки должны быть диагностируемы через browser/WebView logs.
  - Потеря cookies/session должна обрабатываться существующим auth/session flow, без создания отдельной WebView-only идентичности.
  - Недоступность `localStorage`/`sessionStorage` не должна приводить к падению витрины, если соответствующее состояние может быть восстановлено другим способом.
  - Потеря сети во время работы WebView должна приводить к контролируемому состоянию ошибки, а не к silent failure.

- **Security:**
  - Использовать существующий механизм HTTPS.
  - Не хранить API secrets, backend credentials или integration secrets в frontend/WebView.
  - CSP должна разрешать только необходимые источники ресурсов и API.
  - CORS должен разрешать только необходимые frontend origins/credentials согласно существующей архитектуре.
  - Cookies с session/auth данными должны использовать существующие security attributes (`Secure`, `HttpOnly`, `SameSite`) в соответствии с текущим auth flow.
  - `tenant_id`, полученный от клиента, не считать доверенным без серверной валидации/разрешения.
  - Не передавать чувствительные данные через Telegram URL query parameters без отдельного обоснования и защиты.

- **WebView Compatibility:**
  - Telegram In-App Browser рассматривается как отдельный browser runtime с ограничениями по cookies, storage, viewport, navigation и lifecycle.
  - Любая WebView-specific логика должна быть изолирована в frontend compatibility layer и не должна изменять поведение обычного mobile/desktop browser без необходимости.
  - Фактические ограничения, обнаруженные при тестировании, фиксировать в рамках, а не копировать документацию Telegram.

---

## Заметки агента

- **CBR #66.** Серия TG/IG → `/shop`: задача 1 = #64, задача 2 = #65, **эта = задача 3**. Задачи 4 (Mobile UI) и 5 (UX/Performance) — отдельные диалоги. Viewport здесь только чтобы ключевой UI не перекрывался; визуальная полировка и перф — не этот шаг.
- Telegram Bot (`TELEGRAM_BOT_TOKEN`, `Shop::TelegramBotClient`, алерты) — **не** scope. Запрещено добавлять Bot API и менять native bot flows.
- Пути заказчика `src/**`, `TASK-048.test.ts`, `npx tsc` — чужой стек. Канон CoffeeOS: `app/frontend/**` (Svelte) + `node --test test/javascript/*.mjs` + `bin/rails test` зоны shop.
- CORS: витрина same-origin `/shop/api/*` — глобальный CORS не добавлять без proof (канон #64/#65).
- Identity: WebView не подменяет user_id; `tenant_id` только по контракту #65 (query > meta, явный blank ≠ silent fallback).
- `initTelegram()` в `App.svelte` — Mini App `WebApp.ready/expand`, не In-App Browser по ссылке. Не смешивать.
- Instagram — зона #64/#65; эта задача канон-заказчика — **Telegram WebView**. Регрессию IG/Chrome не ломать.
- Приёмка hot-path: Fly **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`. Ручной Telegram на устройстве — финальный acceptance, не блокер local GREEN.
