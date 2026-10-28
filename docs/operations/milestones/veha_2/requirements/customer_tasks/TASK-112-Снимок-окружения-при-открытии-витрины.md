# TASK_112: Снимок окружения при открытии витрины

**ID заказчика:** TASK_112 · **CBR:** #112 · **Дата intake:** 2026-10-28 (шаг 1 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec  
**Артефакты:** нет (только текст)  
**Google Doc:** https://docs.google.com/document/d/1zj0HL_Ws1FbqJFQPC3wSuKmo9msLYN8qrjLqV63afEI/edit  
**Статус:** intake — шаг 1 очереди, `in_progress` · есть миграция (Migration Gate) · попадает в 🚀 1

---

## Текст задачи (дословно) — Google Doc Spec

## TASK_112: Снимок окружения при открытии витрины
**Тип:** новая задача (сценарий нигде не зафиксирован)
Бизнес-цель: узнавать, в каких окружениях гости открывают витрину, что в них доступно для push и есть ли гости с недоступным хранилищем (localStorage, sessionStorage), чтобы решения по iOS, предварительному экрану, плашке установки и приоритету защиты storage опирались на данные. Поведение для гостя не меняется. Единица учёта: сессия (вкладка), людей не считаем. Последующие задачи (TASK-IOS-PUSH-PATH) пишут события воронки установки в ту же таблицу по event_kind.

## 1. Карта интеграций — затронуто / нет
Затронуто: клиентский сбор возможностей окружения; новый публичный endpoint shop API; новая таблица событий с расширяемым белым списком event_kind; чтение в Metabase.
Не затронуто: регистрация push, /shop/api/push/register, VAPID/FCM, Service Worker, каскад, оплата, авторизация, контракты Telegram/Instagram, tenant resolution.
Identity: событие привязано только к точке (tenant), определяемой на сервере (shop/api/base_controller.rb:16,33-38). Идентификатор гостя не пишется.

## 2. Карта компонентов
Новый компонент: app/frontend/lib/pushEnvironment.js (флаги возможностей, без побочных эффектов, кроме короткой пробы хранилища; не вызывает requestPermission и регистрацию Service Worker). Переиспользует на чтение getDeviceOS (deviceDetect.js:13) и isTelegramInAppBrowser (shopWebView.js:7). Метки Instagram и прочих встроенных браузеров определяются внутри pushEnvironment.js.
Проба хранилища: своя, внутри pushEnvironment.js (обращение к геттеру, запись и удаление пробного ключа в try/catch). probeStorage и safeWebStorage из shopWebView.js не вызываются: их подключение относится к TASK-STORAGE-FALLBACK-EXT.
Точка вызова: App.svelte, onMount, после завершения bootstrapShopTenant без перенаправления (App.svelte:111-148; bootstrapShopTenant может сделать window.location.assign, shopTenantHeader.js:141-148,186-194). application.js не затрагивается.
Общий файл с другими задачами: App.svelte (да). Граница: один неблокирующий вызов в try/catch, порядок существующих вызовов не меняется.
Транспорт: по образцу fire-and-forget (shopPwa.js:18-26, subscriptionOffer.js:99-130: sendBeacon, fallback fetch с keepalive).
Бэкенд: новый публичный контроллер shop API, модель, миграция, таблица (рабочее имя shop_environment_events). Ожидаемые поля: point_id (обязательно, только с сервера), created_at, event_kind (по умолчанию session_open), os_family, standalone, notification_state (unavailable/default/granted/denied), push_manager, service_worker, storage_local, storage_session (доступно/недоступно), inapp_label, ua_snippet (только при other_inapp). Имена по конвенциям проекта. marketing_events не подходит: customer_id NOT NULL (schema.rb:394), фиксированные типы (:404), приём только для авторизованного гостя (subscription_offers_controller.rb:49-55).
Политика таблицы: без RLS, по прецеденту marketing_events (миграция 20260929150000_create_marketing_events.rb:3-4); комментарий в миграции с причиной. Решение владельца 2026-10-15. Пересмотреть до запуска дашбордов для франчайзи.
Д7a (ENV-GATE) надстраивает над pushEnvironment.js классы A–E; эта задача класс не определяет.

## 3. Текущее поведение (факт, не требование)
Знание об окружении ограничено getDeviceOS по User-Agent (выбор wallet или push, orderStatusCtaMachine.js:43-44) и isSupported() внутри registerShopPush (firebasePush.js:108-118). Проверок standalone, display-mode, Instagram и других встроенных браузеров нет. isTelegramInAppBrowser существует, но вызывается только из теста (shop_telegram_webview_test.mjs:26-38). Доступность хранилища в рабочем коде не измеряется; safeWebStorage и probeStorage написаны, но не используются (shopWebView.js:33-53). Данных о реальных окружениях гостей нет. mobile_sessions не хранит UA, IP, ОС (schema.rb:495-510). В App.svelte нет ни одного хука «каталог отрисован».

## 4. Scope
Разрешено: pushEnvironment.js; один вызов в App.svelte; публичный endpoint приёма с белым списком event_kind; новая таблица и миграция; тесты; простое представление (view) для Metabase.
Запрещено: менять интерфейс и количество запросов (кроме одного события session_open за сессию); вызывать requestPermission, registerShopPush, регистрацию Service Worker; подключать safeWebStorage и probeStorage; ветвить логику по User-Agent; писать внешние идентификаторы, телефон, e-mail, IP, идентификатор гостя, сырой User-Agent сверх Subtask 8; брать point_id из тела запроса; реализовывать значения event_kind кроме session_open (остальные добавляют свои задачи); отдавать содержимое таблицы через shop API, панели и экраны приложения (читает только Metabase и тесты); использовать для пробы ключ, совпадающий с существующим; менять tenant resolution, CSRF, CORS глобально; менять push, VAPID, каскад; блокирующие действия на boot; новые библиотеки.

## 5. Gherkin
- [ ] Subtask 1: Given гость открыл витрину в любом окружении, When завершён tenant bootstrap без перенаправления, Then отправляется одно событие session_open: standalone (display-mode / navigator.standalone), Notification (есть/нет и permission), PushManager, serviceWorker, localStorage (доступен/недоступен), sessionStorage (доступен/недоступен), семейство ОС (ios/android/other), метка встроенного браузера (telegram/instagram/facebook/other_inapp/none). Для other_inapp признаки WebView: Android — токен wv в User-Agent; iOS — есть Mobile/, нет Safari/. Это эвристика, точность подтверждается ручной проверкой на устройствах; ошибка метки на поведение витрины не влияет.
- [ ] Subtask 2: Given событие session_open уже отправлено в этой вкладке, When гость перемещается по экранам, Then повторного события нет (защита на время жизни вкладки, а при недоступном хранилище на время жизни страницы). Защита относится только к session_open; другие event_kind определяют свои правила в своих задачах. Если bootstrap перезагрузил страницу на другую точку, событие уходит один раз, для итоговой точки. Повторная запись после перезагрузки страницы при недоступном хранилище допустима.
- [ ] Subtask 3: Given отправка не удалась (сеть, 4xx/5xx), Then каталог не затронут, гость ничего не видит, повторов в цикле нет.
- [ ] Subtask 4: Given storage недоступен или проба бросает исключение (SecurityError, QuotaExceeded), When собирается событие, Then bootstrap не ломается, соответствующий флаг = недоступен, защита от повтора работает в памяти страницы.
- [ ] Subtask 5: Given API браузера отсутствует или бросает исключение (Notification, PushManager, matchMedia), Then флаг = unavailable, исключение не пробрасывается.
- [ ] Subtask 6: Given запрос на endpoint без авторизации гостя, When точка определена на сервере, Then событие сохраняется; при неопределённой точке отказ как у остальных shop API.
- [ ] Subtask 7: Given тело с неизвестными ключами, неверными значениями, неизвестным event_kind или избыточным размером, Then неизвестные ключи не сохраняются, неверные значения заменяются на unavailable или other, неизвестный event_kind и избыточный размер отклоняются, частота ограничена (лимит рассчитан на несколько событий за сессию). Перед Build: проверить, есть ли в проекте механизм ограничения частоты, и использовать его; если нет, ввести минимальный лимит на точку, IP не сохраняя.
- [ ] Subtask 8: Given событие сохранено, Then в строке нет идентификатора гостя, IP и сырого User-Agent. Исключение: при метке other_inapp сохраняется ua_snippet не длиннее 300 символов (конец строки не обрезается в пользу начала). Для остальных меток ua_snippet = NULL.
- [ ] Subtask 9: Given накопились события, When владелец открывает Metabase, Then доступно распределение сессий по ОС, standalone и меткам по точке и по дням; доля сессий с недоступным localStorage или sessionStorage по меткам окружений; доля iPhone-сессий во встроенных браузерах (основание решения по плашке для встроенных браузеров в TASK-IOS-PUSH-PATH, Subtask 5); срезы допускают фильтр по event_kind.
- [ ] Subtask 10: Given любое окружение, Then поведение витрины не меняется, существующие тесты bootstrap и каталога зелёные.
- [ ] Subtask 11: Given выполнена проба хранилища, Then пробный ключ удалён, существующие ключи не затронуты, при исправном хранилище в нём не остаётся лишних записей.
- [ ] Subtask 12: Given запрос без event_kind, Then он принимается как session_open (совместимость клиента и сервера при независимой выкладке).

## 6. TDD-проверка: команды
Фронтенд: npm test -- --run (новый тест pushEnvironment: отсутствие API, исключения, ложные значения, эвристика других встроенных браузеров, проба хранилища: исправное, бросает на геттере, бросает на setItem, очистка ключа); npm run lint; npm run typecheck.
Бэкенд: тесты контроллера и модели (путь по фактической структуре test/), в том числе белый список event_kind и значение по умолчанию; bundle exec rubocop.
Ручная проверка: Android Chrome PWA и iPhone с иконки и из Safari-вкладки: событие в БД с верными флагами; Chrome с заблокированными данными сайта: флаги storage = недоступно; сопоставить метки встроенных браузеров с реальными приложениями (Telegram, Instagram, Google Chat).
Документ готов к билду.
## SBR: TASK-PUSH-ENV-SNAPSHOT
## Файлы (ожидаемо): app/frontend/lib/pushEnvironment.js (новый), App.svelte (один вызов), новый контроллер shop API + модель + миграция + view для Metabase, тесты
## Не ломать: порядок вызовов в App.svelte onMount, bootstrapShopTenant, каталог и корзина, tenant resolution, CSRF и CORS; не вызывать registerShopPush и requestPermission; не подключать safeWebStorage и probeStorage; point_id только с сервера; в белом списке event_kind только session_open
## Проверка: npm test -- --run; npm run lint; npm run typecheck; бэкенд-тесты; bundle exec rubocop; ручной прогон Android, iPhone, Telegram, Instagram, Chrome с заблокированными данными сайта
## DoD: Subtask 1–12, поведение витрины не изменилось, данные видны в Metabase, включая долю сессий с недоступным storage и долю iPhone-сессий во встроенных браузерах.

---

## Заметки агента

- Метки в тексте → ID заказчика (по таблице меток [очереди](../PUSH_SMS_QUEUE.md)): TASK-PUSH-ENV-SNAPSHOT = эта задача (TASK_112, Д9); TASK-IOS-PUSH-PATH = TASK_111 (Д8); TASK-STORAGE-FALLBACK-EXT = TASK_114 (Д11); Д7a (ENV-GATE) = TASK_109.
- Сверка шапки с очередью (п. 4 «Как работать»): в документе нет «Зависит от» и «Порядок сборки», статус «Документ готов к билду» — совпадает со строкой 1 очереди (зависимостей нет).
- Миграция → на `/spec` Migration Gate (`coffeeos-dev-gates.mdc`). Таблица без RLS — по прецеденту `marketing_events` и решению владельца 2026-10-15; итог шага 0.4 (TASK_119): в production RLS к роли приложения и так не применяется.
- Факты раздела 2–3 (файл:строка, «Текущее поведение»), наличие механизма ограничения частоты (Subtask 7) и Metabase в окружении сверяем на `/spec`.
