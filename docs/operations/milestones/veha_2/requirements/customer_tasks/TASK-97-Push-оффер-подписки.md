# TASK_97: Push-оффер подписки

**CBR:** #97 · **Дата intake:** 2026-09-29  
**Источник:** Google Doc Spec  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/subscription_offer_push/ (ledger `GATES.md`) · смежные — `artifacts/subscription_offer_frontend_push_analytics/` (TASK_96)  
**Google Doc:** https://docs.google.com/document/d/1VN1VSBHuGtIjluoNFATbmAw0OsfL_UBqKnPho_fTtU4/edit?usp=drivesdk  
**Тип:** новая фича (backend) · **дублирует TASK_96 Subtask 14–21**  
**Статус:** intake `[x]` · ждёт решения владельца (делать отдельно / закрыть в составе TASK_96)

---

## Текст задачи (дословно) — Google Doc Spec

TASK_97: Push-оффер подписки

Бизнес-цель: Отправлять гостю push с предложением подписки при первом и последующих разрешённых показах оффера, синхронно с состоянием `subscription_offer_states`, не дублировать push для одного перехода в `shown` и не отправлять push после покупки или при недоступных push-уведомлениях.

## 1. Связь с картой интеграций

1. **Затронутые сервисы из `@INTEGRATIONS.md`:**
   1. `docs/integrations/pwa-realtime.md` — существующая FCM/push-инфраструктура.
   1. `docs/integrations/notify-loyalty.md` — существующий FCM registration flow и поле `push_enabled_at`.
1. **Смежные модули, которые НЕЛЬЗЯ ломать:**
   1. существующие push о статусе заказа (`Cascade ready`, FCM v1);
   1. существующий FCM registration flow и запись `push_enabled_at`;
   1. `subscription_offer_states` — состояние изменяется правилами задачи A, текущая задача только реагирует на переход в `shown`;
   1. правила `SubscriptionOfferEligibility` и `GrowthPromo`;
   1. Apple Wallet push.

## 2. Связь с картой компонентов

1. **Затронутые компоненты из `@COMPONENT_MAP.md`:** карта компонентов в контексте задачи не передана; необходимо сверить фактическое владение `OfferPresentationService` и FCM/push-модулями перед реализацией.
1. **Общий файл с другой задачей:** нет подтверждённых данных о совместном владении файлами; при обнаружении общего файла Scope необходимо разделить явно.
1. **Новый компонент (не в карте):** да — `Subscriptions::OfferPushNotifier` является новым компонентом, если он отсутствует в текущем `COMPONENT_MAP.md`.

## 3. Разрешенный и Запрещенный Scope

1. **Разрешено менять/создавать:**
   1. `Subscriptions::OfferPushNotifier` — сервис отправки push-оффера через существующую FCM-инфраструктуру;
   1. точечное место в `OfferPresentationService`, отвечающее за side-effect перехода `not_shown → shown`;
   1. шаблон текста push-оффера;
   1. механизм idempotency для конкретного перехода в `shown`;
   1. backend unit/integration tests для `OfferPushNotifier` и `OfferPresentationService`;
   1. тесты regression для push/FCM-зоны, необходимые для подтверждения отсутствия побочных изменений.
1. **Строго запрещено менять:**
   1. существующий FCM registration flow и запись `push_enabled_at`;
   1. push о статусе заказа (`Cascade ready`) и его шаблоны;
   1. логику и структуру `subscription_offer_states`;
   1. `OfferPresentationService` за пределами подключения side-effect отправки push;
   1. `SubscriptionOfferEligibility`;
   1. `GrowthPromo`;
   1. Apple Wallet push.

## 4. Сценарии и Чек-лист (Gherkin)

1. **Subtask 1: Создать `Subscriptions::OfferPushNotifier`**
   1. Given: в проекте существует рабочая FCM-инфраструктура для push-уведомлений.
   1. When: вызывается `OfferPushNotifier` для разрешённого показа оффера.
   1. Then: сервис формирует и передаёт push с предложением подписки через существующую FCM-инфраструктуру; собственная новая push-транспортная инфраструктура не создаётся; ошибки отправки обрабатываются внутри notifier.
1. **Subtask 2: Подключить push к переходу `not_shown → shown`**
   1. Given: `subscription_offer_states.status = not_shown`, а правила задачи A разрешают переход в `shown`.
   1. When: `OfferPresentationService` фиксирует переход в `shown`.
   1. Then: вызывается `OfferPushNotifier` как side-effect этого перехода; успешное вычисление presentation-состояния не зависит от результата доставки push.
1. **Subtask 3: Не отправлять push при отключённых уведомлениях**
   1. Given: у гостя `push_enabled_at = null`.
   1. When: состояние оффера переходит из `not_shown` в `shown`.
   1. Then: push не отправляется; баннер и карточка ЛК продолжают работать независимо от наличия push-разрешения.
1. **Subtask 4: Реализовать idempotency для одного перехода в `shown`**
   1. Given: один и тот же переход состояния в `shown` обрабатывается несколько раз, например из-за параллельных вызовов `profile/config`.
   1. When: `OfferPushNotifier` получает запрос на отправку.
   1. Then: для одного конкретного перехода push отправляется не более одного раза; idempotency-ключ привязан к переходу в `shown`, а не к заказу или календарной дате.
1. **Subtask 5: Отправлять новый push при повторном показе после 3 заказов**
   1. Given: после ранее завершённого показа срабатывает правило повторного показа из задачи A и состояние снова переходит в `shown`.
   1. When: фиксируется новый переход в `shown`.
   1. Then: отправляется новый push; idempotency-ключ предыдущего перехода не блокирует новую отправку.
1. **Subtask 6: Не отправлять push после покупки**
   1. Given: `subscription_offer_states.status = purchased`.
   1. When: выполняется обработка любых последующих статусов заказов или presentation-запросов.
   1. Then: push с предложением подписки не отправляется.
1. **Subtask 7: Не отправлять push при доступном промо 11₽**
   1. Given: `GrowthPromo.available?(customer, point) = true`.
   1. When: `OfferPresentationService` вычисляет presentation-состояние.
   1. Then: переход в `shown` не выполняется согласно приоритету задачи A; `OfferPushNotifier` не вызывается.
1. **Subtask 8: Обработать ошибку FCM без каскадного влияния**
   1. Given: FCM возвращает ошибку при отправке push-оффера.
   1. When: `OfferPushNotifier` обрабатывает ошибку.
   1. Then: ошибка логируется и не выбрасывается в вызывающий presentation-flow; существующие push о статусе заказа продолжают работать независимо от ошибки push-оффера.
1. **Subtask 9: Проверить отсутствие регрессии существующего FCM**
   1. Given: в системе существуют push о статусе заказа (`Cascade ready`) и FCM registration flow.
   1. When: выполняется полный regression-набор push/FCM-тестов.
   1. Then: существующие push о статусах заказов и registration flow проходят без изменений поведения.

## 5. Команды TDD-проверки

1. **Запуск тестов:** существующий backend test runner для `OfferPushNotifier`, `OfferPresentationService` и push/FCM regression suite.
1. **Проверка типов:** существующая команда backend type-check проекта.

## SBR

Текущая фаза: **SPEC**

## Файлы (ожидаемо)

1. `Subscriptions::OfferPushNotifier`
1. `OfferPresentationService` — только подключение side-effect отправки push при переходе в `shown`
1. шаблон push-оффера
1. backend unit/integration tests для notifier и presentation flow
1. regression tests push/FCM зоны

## Не ломать

1. FCM registration flow и `push_enabled_at`
1. существующие push о статусе заказа (`Cascade ready`)
1. шаблоны push о статусе заказа
1. `subscription_offer_states` — состояние не изменять, только читать результат перехода
1. `SubscriptionOfferEligibility`
1. `GrowthPromo`
1. Apple Wallet push
1. не создавать отдельную push-инфраструктуру
1. idempotency не должен быть привязан к заказу или календарной дате
1. если `OfferPushNotifier` отсутствует в `COMPONENT_MAP.md`, после реализации добавить его в карту как новый компонент

## Проверка

1. backend unit/integration tests для `OfferPushNotifier`
1. tests `OfferPresentationService`
1. тест отсутствия отправки при `push_enabled_at = null`
1. тест повторной отправки при новом переходе в `shown`
1. тест idempotency при параллельных вызовах
1. тест блокировки для `purchased`
1. тест блокировки при доступном `GrowthPromo`
1. тест обработки ошибки FCM без влияния на push статуса заказа
1. полный regression suite push/FCM

## DoD

1. `OfferPushNotifier` отправляет push через существующую FCM-инфраструктуру.
1. Push запускается только как side-effect разрешённого перехода в `shown`.
1. При `push_enabled_at = null` отправки нет.
1. Один переход в `shown` создаёт не более одной отправки.
1. Новый разрешённый переход в `shown` создаёт новый push.
1. При `purchased` push не отправляется.
1. При доступном промо 11₽ переход в `shown` и push не выполняются.
1. Ошибка FCM логируется и не ломает presentation-flow или существующие push о статусе заказа.
1. Regression push/FCM проходит без изменения существующего поведения.
1. Изменения ограничены разрешённым Scope.

---

## Заметки агента

- Патчей / EXT / доп.задач в Google Doc нет (1 вкладка, 0 комментариев на 2026-09-29).
- «Задача A» в тексте = TASK_95 (владелец `mark_shown` / state machine, `OfferPresentationService`).
- **Полное пересечение с TASK_96 Subtask 14–21** (`OfferPushNotifier`, side-effect `not_shown → shown`, `push_enabled_at`, idempotency на переход, повтор после 3 заказов, `purchased`, промо 11₽, ошибка FCM, regression). TASK_96 уже на RED (`todo.md`, решение SPEC №6–7: idempotency = id `banner_shown` на переход, notifier по образцу `Shop::OrderStatusPushNotifier`) — решения совместимы с текстом TASK_97.
- Отличие от TASK_96: TASK_97 — только backend, без deep link `offer_url` в SW и без `push_sent`/`marketing_events` → не зависит от billing UI.
- Решение нужно от владельца: закрыть TASK_97 в составе GREEN TASK_96 или вести отдельным SBR.
