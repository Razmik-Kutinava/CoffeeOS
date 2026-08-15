# UX и Performance мобильной витрины CoffeeOS внутри Telegram WebView

**Дата интейка:** 2026-08-15
**Источник:** текст заказчика (передан владельцем в чат)
**CBR:** #68
**Артефакты:** docs/operations/milestones/veha_2/artifacts/mobile_storefront_telegram_webview_ux_perf/

---

## Текст заказчика (дословно)

Задачи: UX и Performance мобильной витрины CoffeeOS внутри Telegram WebView
Бизнес-цель:
После реализации «Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser» и «Адаптация Mobile UI витрины CoffeeOS под Telegram WebView» обеспечить быстрый, устойчивый и предсказуемый UX мобильной витрины внутри Telegram WebView.
Пользователь должен быстро получать контент, видеть понятное состояние загрузки, не сталкиваться с пустыми экранами и бесконечными loading-состояниями, а при проблемах сети иметь понятные сценарии retry/offline/recovery.
Связь с картой интеграций
Затронутые сервисы из @INTEGRATIONS.md:
Telegram In-App Browser / Telegram WebView.
CoffeeOS Mobile Storefront / PWA.
Backend API CoffeeOS.
CDN/static asset delivery для изображений, если используется.
Зависит от задач:
«Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser»
«Адаптация Mobile UI витрины CoffeeOS под Telegram WebView»
Смежные модули, которые НЕЛЬЗЯ ломать:
каталог;
загрузку товаров;
корзину;
checkout;
tenant_id;
авторизацию и session;
существующий storage;
мобильную витрину вне Telegram.
Разрешенный и Запрещенный Scope
Разрешено менять/создавать
src/components/** — loading, skeleton, error, retry и performance-related UI.
src/routes/** — состояния загрузки и ошибок мобильной витрины.
src/lib/** — cache, retry, offline/network detection и performance utilities.
src/services/** — frontend API request/cache/retry behavior.
src/styles/**, src/app.css — стили loading/skeleton/error states.
static/**, public/** — оптимизация frontend assets, если они находятся в этих директориях.
tests/** — тесты данной задачи.
Существующую CDN/static asset configuration — только если изменение необходимо для оптимизации frontend assets.
Строго запрещено менять
структуру БД;
бизнес-логику каталога;
бизнес-логику корзины;
платежную бизнес-логику;
auth/session business logic;
tenant resolution;
Telegram Bot API;
существующие API contracts;
viewport/safe-area/keyboard mechanics из «Адаптация Mobile UI витрины CoffeeOS под Telegram WebView», если изменение не требуется непосредственно для устранения performance-проблемы;
desktop UI без отдельного regression coverage.
Сценарии и Чек-лист (Gherkin)
Базовый performance budget мобильной витрины
Given: пользователь открывает витрину внутри Telegram WebView.
When: выполняется cold start.
Then: определены измеримые критерии initial render, skeleton и появления первого полезного контента.
Оптимизация initial loading каталога
Given: пользователь впервые открывает витрину.
When: начинается загрузка каталога.
Then: критический UI отображается без ожидания второстепенных ресурсов.
Skeleton первичной загрузки
Given: данные каталога еще не загружены.
When: пользователь открывает витрину.
Then: отображается skeleton соответствующей структуры вместо пустого экрана.
Предотвращение layout shift при загрузке изображений
Given: изображения товаров загружаются асинхронно.
When: изображение становится доступно.
Then: его загрузка не вызывает критического смещения контента или изменения scroll position.
Оптимизация изображений товаров
Given: каталог содержит изображения различных размеров.
When: изображения загружаются внутри Telegram WebView.
Then: frontend не загружает избыточные по размеру ресурсы для мобильного viewport.
Lazy loading изображений
Given: часть товаров находится за пределами текущего viewport.
When: пользователь открывает каталог.
Then: второстепенные изображения не блокируют initial render и загружаются по мере необходимости.
Fallback при ошибке изображения
Given: изображение товара недоступно.
When: браузер получает ошибку загрузки asset.
Then: отображается placeholder, layout не ломается, пользователь продолжает работу с товаром.
Cache данных витрины
Given: пользователь ранее успешно загружал каталог.
When: он повторно открывает витрину.
Then: допустимые cached данные используются для ускорения отображения.
Cache invalidation
Given: существуют cached данные каталога.
When: cache устаревает или backend возвращает актуальные данные.
Then: frontend обновляет данные и не использует stale cache бесконечно.
Stale-while-revalidate каталога
Given: имеется допустимый cached каталог.
When: пользователь повторно открывает витрину.
Then: cached content отображается быстро, после чего выполняется фоновое обновление.
Retry временной ошибки API
Given: запрос каталога завершился временной network error.
When: пользователь нажимает retry.
Then: запрос выполняется повторно без полной перезагрузки страницы.
Защита retry от дублирующих запросов
Given: предыдущий retry-запрос еще выполняется.
When: пользователь повторно нажимает retry.
Then: не создаются неконтролируемые параллельные запросы.
Offline state
Given: Telegram WebView теряет сетевое соединение.
When: пользователь находится на витрине.
Then: приложение показывает понятное offline состояние и не падает.
Recovery после восстановления сети
Given: приложение находится в offline state.
When: сетевое соединение восстанавливается.
Then: приложение возвращается в online state и выполняет необходимое обновление данных.
Разделение network и server errors
Given: API-запрос завершился ошибкой.
When: frontend получает network failure или HTTP error.
Then: UI различает сетевую ошибку, серверную ошибку и отсутствие данных.
Понятное error state
Given: каталог невозможно загрузить.
When: допустимые попытки загрузки завершились ошибкой.
Then: пользователь видит понятное сообщение и доступное действие retry.
Сохранение контента при background refresh error
Given: каталог уже отображается.
When: фоновое обновление данных завершается ошибкой.
Then: существующий валидный контент не исчезает полностью.
Performance при большом каталоге
Given: каталог содержит большое количество товаров.
When: пользователь прокручивает витрину внутри Telegram WebView.
Then: scroll остается отзывчивым, а загрузка изображений не создает критической нагрузки на память и сеть.
Повторное открытие после cache
Given: каталог был ранее загружен и закеширован.
When: пользователь повторно открывает витрину.
Then: контент появляется быстрее cold start, а cache не нарушает tenant_id.
Сохранение состояния корзины
Given: пользователь добавил товары в корзину.
When: происходит retry, offline/online transition или background refresh.
Then: состояние корзины не теряется.
Безопасная работа cache/storage в Telegram WebView
Given: WebView предоставляет ограниченный storage lifecycle.
When: приложение читает или записывает cache.
Then: ошибка storage не приводит к падению приложения.
Regression tests UX/Performance
Given: реализованы loading, image optimization, cache, retry, offline и error states.
When: запускаются тесты задачи.
Then: основные состояния покрыты regression tests.
Ручная performance-проверка в Telegram WebView
Given: предыдущие задачи завершены.
When: выполняются cold start, повторное открытие, offline/online transition и работа с большим каталогом.
Then: отсутствуют критические задержки, бесконечный loading, пустые экраны и потеря пользовательского состояния.
Команды TDD-проверки
Запуск тестов: npm test tests/integration/TASK-WEBVIEW-UX-PERF.test.ts
Проверка типов: npx tsc --noEmit
Acceptance: ручная проверка UX/performance внутри реального Telegram In-App Browser обязательна.
Definition of Done
Initial render не блокируется второстепенными ресурсами.
Skeleton отображается во время первичной загрузки.
Изображения оптимизированы для мобильного WebView.
Нет критического layout shift.
Cache ускоряет повторное открытие и имеет контролируемую актуальность.
Retry не создает дублирующие запросы.
Offline state отображается явно.
После восстановления сети приложение корректно восстанавливается.
Network и server errors имеют разные UX-состояния.
Background refresh error не уничтожает уже отображенный контент.
Корзина не теряет состояние.
Cache/storage не нарушает tenant_id.
Regression tests проходят.
Performance проверена в реальном Telegram WebView.

---

## БЛОК 2: .cursor/tasks/TASK-WEBVIEW-UX-PERF/todo.md

TODO: TASK-WEBVIEW-UX-PERF
Базовый performance budget мобильной витрины
Оптимизация initial loading каталога
Skeleton первичной загрузки
Предотвращение layout shift при загрузке изображений
Оптимизация изображений товаров
Lazy loading изображений
Fallback при ошибке изображения
Cache данных витрины
Cache invalidation
Stale-while-revalidate каталога
Retry временной ошибки API
Защита retry от дублирующих запросов
Offline state
Recovery после восстановления сети
Разделение network и server errors
Понятное error state
Сохранение контента при background refresh error
Performance при большом каталоге
Повторное открытие после cache
Сохранение состояния корзины
Безопасная работа cache/storage в Telegram WebView
Regression tests UX/Performance
Ручная performance-проверка в Telegram WebView

---

## БЛОК 3: INTEGRATIONS.md Update

## Изменения в связке: Telegram In-App Browser / WebView → CoffeeOS UX / Performance

- **Точки входа:**
  - Mobile storefront, открытый внутри Telegram In-App Browser.
  - Существующие CoffeeOS API endpoints для загрузки каталога и связанных данных.
  - Существующая CDN/static asset delivery для изображений.
  - Новые backend endpoints для performance-механики не требуются.

- **Identity Mapping:**
  - Эта задача не изменяет identity mapping.
  - Cache и offline данные должны быть изолированы по tenant context.
  - `tenant_id` не должен определяться только из cached данных.
  - Cache одного tenant не может использоваться для отображения данных другого tenant.

- **Handling Errors:**
  - Временная network error → error/loading state → retry.
  - Потеря сети → offline state.
  - Восстановление сети → online state + необходимое обновление данных.
  - HTTP 4xx/5xx → соответствующее error state без бесконечного retry.
  - Ошибка изображения → placeholder без разрушения layout.
  - Ошибка background refresh → сохранить уже отображенный валидный контент.
  - Ошибка cache/storage → продолжить работу через network path, если он доступен.
  - Повторные retry не должны создавать неконтролируемые параллельные запросы.

- **Security:**
  - Cache не должен использоваться как источник authentication credentials.
  - Не хранить API secrets или backend credentials в WebView storage.
  - Cached данные должны быть связаны с корректным tenant/user context.
  - Offline режим не должен обходить серверную авторизацию или tenant validation.
  - CDN/image resources используют существующую безопасную схему доставки.

- **Performance / WebView Compatibility:**
  - Initial render отделяется от загрузки второстепенных ресурсов.
  - Изображения загружаются с учетом мобильного viewport.
  - Cache является UX/performance оптимизацией, а не заменой backend source of truth.
  - Offline cache не должен приводить к отображению данных другого tenant.
  - Skeleton, error и retry UI должны работать в пределах viewport, safe-area и keyboard constraints, определенных задачей «Адаптация Mobile UI витрины CoffeeOS под Telegram WebView».

---

## Заметки агента

- **CBR #68.** Серия TG/IG → `/shop`: задача 1 = #64, задача 2 = #65, задача 3 = #66 (runtime), задача 4 = #67 (Mobile UI), **эта = задача 5 (UX/Performance)**.
- Пути заказчика `src/**`, `src/services/**`, `static/**`, `.cursor/tasks/TASK-WEBVIEW-UX-PERF/todo.md`, `npm test tests/integration/TASK-WEBVIEW-UX-PERF.test.ts`, `npx tsc --noEmit` — чужой стек. Канон CoffeeOS: `app/frontend/**` (Svelte) + живой чеклист `docs/operations/session/todo.md` + `node --test test/javascript/shop_telegram_webview_ux_perf_test.mjs`. Prisma / tsc / новые backend endpoints — **не трогать**.
- Контракт INTEGRATIONS: индекс `INTEGRATIONS.md` + секция `shop-api.md` § WebView UX/perf (#68). Отдельный секционный файл не плодить.
- #66 уже: `catalogCacheKey(tenant_id)`, storage try/catch + memory fallback, `--shop-vvh`. #67 уже: `shopWebViewLayout.js`, CartSheet/Header в visual viewport. Эта задача **не** переписывает runtime/layout.
- Уже есть (не дублировать): `PageSkeleton`, cache-on-error, `inflight` в `loadCatalog`, `aspect-[4/3]` + `onerror` «Нет фото», глобальный `ShopPwaBanner` offline, `shopLocalStorage` try/catch. Дыры GREEN: SWR при reopen, retry не обязан ставить skeleton поверх меню, `loading="lazy"`, kind сеть vs HTTP vs empty в UI каталога.
- API отдаёт один `image_url` без вариантов/srcset — новые thumbnail endpoints запрещены (контракт). Оптимизация: lazy ниже fold + CLS через существующий aspect-ratio, не выдумывать CDN-трансформы.
- Performance budget local: измеримо в node-тестах (skeleton только без кэша; SWR отдаёт cache до API; inflight coalesce; error kind). Lighthouse/Device Lab — ручной acceptance после deploy, не блокер local GREEN.
- Корзина: retry/offline/SWR каталога не вызывают `cartSheetStore` reset и не размонтируют `CartSheet`. Не трогать cart business logic.
- Offline баннер уже есть (`ShopPwaBanner`) — не второй overlay. Каталог использует `shopOnline` / `isOfflineError` + кэш.
- `tenant_id` только контракт #65 (query > meta). Кэш ключ `coffeeos_shop_catalog_v1:<tenant_id>`; URL tenant побеждает кэш другой точки.
- Приёмка hot-path: Fly **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`. Ручной Telegram — после апрува deploy #67/#68. #67 CI green, deploy ещё апрув — не блокер local RED/GREEN #68.
