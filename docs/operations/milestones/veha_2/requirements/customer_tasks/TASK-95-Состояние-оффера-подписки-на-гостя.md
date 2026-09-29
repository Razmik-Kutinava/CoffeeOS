# TASK_95: Состояние оффера подписки на гостя

**CBR:** #95 · **Дата intake:** 2026-09-29  
**Источник:** Google Doc Spec  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/subscription_offer_guest_state/  
**Google Doc:** https://docs.google.com/document/d/18f25SUyeTWwixkcDX9XvTedfkd8GzSO6lfjoCTNWzPA/edit?usp=drivesdk  
**Тип:** новая фича (не патч, не доп.задача) · полный SBR  
**Статус:** intake `[x]` · ждёт `/spec`

---

## Текст задачи (дословно) — Google Doc Spec

TASK_95: Состояние оффера подписки на гостя

Бизнес-цель: Ввести персональное состояние оффера подписки для каждого гостя, чтобы баннер, карточка в ЛК и push использовали согласованное состояние (`показан / смахнут / ждёт в ЛК / куплен`), повторный показ выполнялся после 3 новых завершённых заказов после смахивания, а решение о доступности оффера учитывало приоритет промо 11₽.

## 1. Связь с картой интеграций

- **Затронутые сервисы из `@INTEGRATIONS.md`:**
  - `docs/integrations/shop-api.md` — контракт `profile/config` и новые endpoint'ы состояния оффера.
  - `docs/integrations/pwa-realtime.md` — точка определения показа баннера при достижении заказа статуса `ready`.
- **Новые изменения интеграционного контракта:**
  - `profile/config` должен возвращать `should_show_banner` и `has_unread_offer_in_lk` как вычисляемые backend-поля.
  - Добавить `POST /shop/api/subscription_offer/dismiss` для фиксации смахивания.
  - Добавить `POST /shop/api/subscription_offer/viewed` для фиксации просмотра оффера в ЛК.
- **Смежные модули, которые НЕЛЬЗЯ ломать:**
  - `SubscriptionOfferEligibility` — существующая логика eligibility не изменяется, её результат используется как вход.
  - `subscription_offer_settings` — point-scoped пороги только читаются.
  - `GrowthPromo` и существующий promo-11₽ flow — используется только `GrowthPromo.available?`.
  - `orderStatusCtaMachine.js` и существующая CTA-логика `ready`.
  - `Subscriptions::PurchaseService` — не изменять бизнес-логику покупки; допускается только добавление side-effect `mark_purchased` после успешной покупки.
  - `subscription_plans`, `subscriptions`, `Payments::TbankAdapter`.

## 2. Связь с картой компонентов

- **Затронутые компоненты из `@COMPONENT_MAP.md`:** карта компонентов не передана в контексте; перед реализацией Cursor обязан проверить актуальный `docs/operations/session/COMPONENT_MAP.md`.
- **Общий файл с другой задачей:** нет подтверждённого общего файла; если актуальная карта покажет общий файл, Scope необходимо разделить по владельцам до начала реализации.
- **Новый компонент (не в карте):** да — `Subscriptions::OfferPresentationService` и модель/слой состояния `subscription_offer_states` являются новыми компонентами и должны быть добавлены в карту после реализации.

## 3. Разрешенный и Запрещенный Scope

- **Разрешено менять/создавать:**
  - миграцию и модель `subscription_offer_states`;
  - `Subscriptions::OfferPresentationService`;
  - методы `mark_shown`, `mark_dismissed`, `mark_viewed_in_lk`, `mark_purchased`;
  - backend-логику, формирующую `profile/config`;
  - backend routes/controllers для:
    - `POST /shop/api/subscription_offer/dismiss`;
    - `POST /shop/api/subscription_offer/viewed`;
  - backend unit/integration/E2E tests для состояния оффера;
  - `docs/integrations/shop-api.md`;
  - `docs/integrations/pwa-realtime.md`;
  - `docs/operations/session/COMPONENT_MAP.md` — только для регистрации новых компонентов данной задачи.
- **Строго запрещено менять:**
  - `SubscriptionOfferEligibility`;
  - `subscription_offer_settings`;
  - бизнес-логику `GrowthPromo` и promo-11₽ flow;
  - `orderStatusCtaMachine.js`;
  - frontend-компоненты баннера, ЛК и push;
  - `subscription_plans`;
  - `subscriptions`;
  - бизнес-логику `Subscriptions::PurchaseService` — кроме вызова `mark_purchased` после успешной покупки;
  - `Payments::TbankAdapter`;
  - файлы и компоненты, принадлежащие другим задачам согласно актуальному `COMPONENT_MAP.md`;
  - любые новые отдельные `todo-[feature].md` файлы.

## 4. Сценарии и Чек-лист (Gherkin)

- [ ] **Subtask 1: Создать таблицу состояния оффера**
  - Given: в БД отсутствует таблица состояния оффера.
  - When: применяется миграция.
  - Then: создаётся `subscription_offer_states` с полями `customer_id`, `status`, `first_shown_at`, `last_dismissed_at`, `completed_orders_count_at_dismissal`, `unread_since`, timestamps; `customer_id` поддерживает единственную запись состояния на гостя.

- [ ] **Subtask 2: Создать модель состояния оффера**
  - Given: существует таблица `subscription_offer_states`.
  - When: приложение загружает состояние гостя.
  - Then: модель корректно читает и сохраняет статусы `not_shown`, `shown`, `dismissed`, `viewed_in_lk`, `purchased`.

- [ ] **Subtask 3: Гарантировать единственность состояния гостя**
  - Given: для `customer_id` уже существует состояние оффера.
  - When: сервис выполняет создание или обновление состояния.
  - Then: используется upsert/find-or-create семантика и вторая запись для того же `customer_id` не создаётся.

- [ ] **Subtask 4: Реализовать `OfferPresentationService`**
  - Given: доступны `customer`, `point`, результат `SubscriptionOfferEligibility.check`, `GrowthPromo.available?` и текущее состояние оффера.
  - When: сервис вычисляет presentation-состояние.
  - Then: возвращаются `should_show_banner`, `should_show_push` и `has_unread_offer_in_lk` без доверия значениям, переданным frontend.

- [ ] **Subtask 5: Заблокировать оффер при доступном промо 11₽**
  - Given: `GrowthPromo.available?(customer, point) = true`.
  - When: `OfferPresentationService` вычисляет `should_show_banner`.
  - Then: `should_show_banner = false` независимо от `SubscriptionOfferEligibility.check`.

- [ ] **Subtask 6: Разрешить дальнейшее вычисление после исчерпания промо**
  - Given: `GrowthPromo.available?(customer, point) = false` и `SubscriptionOfferEligibility.check(customer, point) = true`.
  - When: сервис вычисляет presentation-состояние.
  - Then: промо 11₽ больше не блокирует оффер и применяются правила состояния `not_shown`, `dismissed`, `viewed_in_lk`, `purchased`.

- [ ] **Subtask 7: Реализовать первый показ оффера**
  - Given: состояние `not_shown`, гость eligible, промо 11₽ недоступно.
  - When: гость достигает статуса заказа `ready`.
  - Then: `should_show_banner = true`.

- [ ] **Subtask 8: Зафиксировать фактический показ**
  - Given: баннер действительно отрендерен frontend.
  - When: вызывается `mark_shown`.
  - Then: состояние переходит `not_shown → shown`, `first_shown_at` заполняется, а для первого нового показа создаётся `unread_since`.

- [ ] **Subtask 9: Зафиксировать смахивание**
  - Given: состояние оффера `shown`.
  - When: вызывается `mark_dismissed`.
  - Then: состояние переходит в `dismissed`, `last_dismissed_at` получает текущее время, `completed_orders_count_at_dismissal` сохраняет текущее количество завершённых заказов.

- [ ] **Subtask 10: Заблокировать повторный баннер до трёх заказов**
  - Given: состояние `dismissed` и `completed_orders_count - completed_orders_count_at_dismissal < 3`.
  - When: гость снова достигает `ready`.
  - Then: `should_show_banner = false`, а `has_unread_offer_in_lk = true`.

- [ ] **Subtask 11: Разрешить повторный баннер после трёх заказов**
  - Given: состояние `dismissed` и `completed_orders_count - completed_orders_count_at_dismissal >= 3`.
  - When: гость достигает `ready`.
  - Then: `should_show_banner = true`.

- [ ] **Subtask 12: Не использовать старый счётчик после повторного показа**
  - Given: повторный показ после трёх завершённых заказов разрешён.
  - When: вызывается `mark_shown`.
  - Then: состояние переходит в `shown`, а `completed_orders_count_at_dismissal` не используется для нового цикла до следующего `mark_dismissed`.

- [ ] **Subtask 13: Зажигать unread-точку после показа**
  - Given: баннер показан впервые или повторно.
  - When: выполняется `mark_shown`.
  - Then: `has_unread_offer_in_lk = true`; `unread_since` заполняется, если для текущего показа unread-состояние ещё не создано.

- [ ] **Subtask 14: Погасить unread-точку при просмотре в ЛК**
  - Given: `has_unread_offer_in_lk = true`.
  - When: вызывается `mark_viewed_in_lk`.
  - Then: `unread_since = null`, `has_unread_offer_in_lk = false`, состояние переходит в `viewed_in_lk`, если оно ещё не `purchased`.

- [ ] **Subtask 15: Не создавать unread без нового показа**
  - Given: состояние `viewed_in_lk` и новый показ баннера не произошёл.
  - When: гость повторно открывает ЛК.
  - Then: `has_unread_offer_in_lk = false`.

- [ ] **Subtask 16: Зафиксировать успешную покупку**
  - Given: `Subscriptions::PurchaseService` успешно завершил покупку подписки.
  - When: выполняется side-effect `mark_purchased`.
  - Then: состояние переходит в `purchased`, а `should_show_banner` и `has_unread_offer_in_lk` становятся `false`.

- [ ] **Subtask 17: Заблокировать оффер для purchased-гостя**
  - Given: состояние `purchased`.
  - When: гость проходит `ready` на любой точке сети.
  - Then: `should_show_banner = false` и `has_unread_offer_in_lk = false` независимо от eligibility и других условий.

- [ ] **Subtask 18: Расширить `profile/config`**
  - Given: авторизованный гость вызывает `profile/config`.
  - When: backend формирует ответ.
  - Then: ответ содержит `should_show_banner: boolean` и `has_unread_offer_in_lk: boolean`, вычисленные через `OfferPresentationService`.

- [ ] **Subtask 19: Реализовать endpoint смахивания**
  - Given: авторизованный гость вызывает `POST /shop/api/subscription_offer/dismiss`.
  - When: endpoint обрабатывает запрос.
  - Then: выполняется логика `mark_dismissed`; повторный вызов в состоянии, отличном от `shown`, не создаёт некорректный новый цикл состояния.

- [ ] **Subtask 20: Реализовать endpoint просмотра в ЛК**
  - Given: авторизованный гость вызывает `POST /shop/api/subscription_offer/viewed`.
  - When: endpoint обрабатывает запрос.
  - Then: выполняется `mark_viewed_in_lk`; повторный вызов является безопасным и идемпотентным.

- [ ] **Subtask 21: Защитить endpoint смахивания**
  - Given: запрос к `POST /shop/api/subscription_offer/dismiss` не содержит валидной пользовательской сессии.
  - When: backend обрабатывает запрос.
  - Then: возвращается стандартная ошибка авторизации, состояние оффера не изменяется.

- [ ] **Subtask 22: Защитить endpoint просмотра**
  - Given: запрос к `POST /shop/api/subscription_offer/viewed` не содержит валидной пользовательской сессии.
  - When: backend обрабатывает запрос.
  - Then: возвращается стандартная ошибка авторизации, состояние оффера не изменяется.

- [ ] **Subtask 23: Покрыть полный lifecycle интеграционным тестом**
  - Given: eligible-гость без доступного промо 11₽.
  - When: последовательно выполняются первый показ, смахивание, три завершённых заказа, повторный показ, просмотр в ЛК и успешная покупка.
  - Then: на каждом переходе значения `status`, `should_show_banner` и `has_unread_offer_in_lk` соответствуют state machine.

- [ ] **Subtask 24: Покрыть промо-приоритет интеграционным тестом**
  - Given: гость eligible, но `GrowthPromo.available? = true`.
  - When: гость проходит несколько заказов.
  - Then: `should_show_banner = false`, состояние не переходит в `shown` до момента недоступности промо 11₽.

- [ ] **Subtask 25: Выполнить regression-проверку subscription/growth-promo зоны**
  - Given: реализация состояния оффера завершена.
  - When: запускается существующий test suite subscription/growth-promo зоны.
  - Then: существующая логика eligibility, promo-11₽ и покупки не имеет регрессий.

- [ ] **Subtask 26: Обновить документацию Shop API**
  - Given: новые поля `profile/config` и endpoint'ы реализованы.
  - When: обновляется `docs/integrations/shop-api.md`.
  - Then: документ описывает только контракт нашей интеграции: точки входа, mapping пользователя, ответы и ошибки новых endpoint'ов.

- [ ] **Subtask 27: Обновить документацию PWA realtime**
  - Given: состояние показа определяется в существующей точке `ready`.
  - When: обновляется `docs/integrations/pwa-realtime.md`.
  - Then: зафиксировано, что backend возвращает presentation-состояние оффера, а frontend не вычисляет eligibility самостоятельно.

- [ ] **Subtask 28: Зарегистрировать новые компоненты в Component Map**
  - Given: реализация создаёт `Subscriptions::OfferPresentationService` и `subscription_offer_states`.
  - When: обновляется `docs/operations/session/COMPONENT_MAP.md`.
  - Then: новые компоненты имеют указанного владельца — текущую задачу — и ограничения на изменение другими задачами.

## 5. Команды TDD-проверки

- **Запуск unit/integration тестов:** существующий test runner проекта с таргетом subscription offer state.
- **Проверка типов:** `npx tsc --noEmit`.
- **Regression:** полный существующий test suite subscription/growth-promo зоны.
## Состояние оффера подписки — `subscription_offer_state`

### SBR
Текущая фаза: SPEC

### Файлы (ожидаемо)
- миграция и модель `subscription_offer_states`
- `Subscriptions::OfferPresentationService`
- backend routes/controllers для:
  - `POST /shop/api/subscription_offer/dismiss`
  - `POST /shop/api/subscription_offer/viewed`
- backend-контракт `profile/config`
- backend unit/integration/E2E tests состояния оффера
- `docs/integrations/shop-api.md`
- `docs/integrations/pwa-realtime.md`
- `docs/operations/session/COMPONENT_MAP.md`

### Не ломать
- `SubscriptionOfferEligibility` — только чтение результата.
- `subscription_offer_settings` — только чтение.
- `GrowthPromo` и promo-11₽ flow — только чтение `GrowthPromo.available?`.
- `orderStatusCtaMachine.js`.
- `subscription_plans`.
- `subscriptions`.
- `Subscriptions::PurchaseService` — не менять бизнес-логику покупки; только добавить `mark_purchased` после успешной покупки.
- `Payments::TbankAdapter`.
- frontend баннера, ЛК и push — принадлежат отдельным задачам.
- компоненты/файлы, принадлежащие другим задачам согласно актуальному `COMPONENT_MAP.md`.
- не создавать отдельный `todo-[feature].md`.

### Проверка
- существующий test runner проекта для unit/integration тестов subscription offer state;
- `npx tsc --noEmit`;
- полный regression suite subscription/growth-promo зоны.

### DoD
- создана единственная запись `subscription_offer_states` на `customer_id`;
- реализована state machine `not_shown → shown → dismissed/viewed_in_lk → purchased`;
- `GrowthPromo.available? = true` блокирует показ оффера;
- после смахивания повторный показ разрешается только после 3 новых завершённых заказов;
- `has_unread_offer_in_lk` загорается после показа и гасится после просмотра в ЛК;
- purchased-гость больше не получает оффер;
- `profile/config` возвращает `should_show_banner` и `has_unread_offer_in_lk`;
- реализованы и защищены `dismiss` и `viewed` endpoint'ы;
- полный lifecycle покрыт тестом;
- promo-priority покрыт тестом;
- regression subscription/growth-promo проходит;
- `docs/integrations/shop-api.md` и `docs/integrations/pwa-realtime.md` актуализированы;
- новые компоненты зарегистрированы в `docs/operations/session/COMPONENT_MAP.md`.
## Состояние оффера подписки — изменения в связке: Shop API

- **Точки входа:**
  - `GET /shop/api/profile/config` — возвращает presentation-состояние оффера.
  - `POST /shop/api/subscription_offer/dismiss` — фиксирует смахивание.
  - `POST /shop/api/subscription_offer/viewed` — фиксирует просмотр в ЛК.
  - Существующая точка обработки статуса заказа `ready` использует вычисленное backend-состояние для решения о показе баннера.
- **Identity Mapping:**
  - авторизованная сессия гостя -> внутренний `customer_id`;
  - `subscription_offer_states.customer_id` является внутренним идентификатором владельца состояния;
  - `point` используется при вычислении eligibility и доступности `GrowthPromo`, но состояние оффера хранится на уровне гостя, а не точки.
- **Handling Errors:**
  - неавторизованный запрос к `dismiss` или `viewed` отклоняется стандартной ошибкой авторизации;
  - повторный вызов `dismiss` или `viewed` не должен создавать новый цикл состояния;
  - сбой записи состояния не должен приводить к изменению существующего статуса покупки или eligibility.
- **Security:**
  - новые write-endpoint'ы доступны только авторизованному гостю;
  - `customer_id` берётся из валидной серверной сессии и не принимается как доверенный идентификатор из тела запроса;
  - frontend не определяет eligibility или право на показ самостоятельно;
  - состояние `should_show_banner` и `has_unread_offer_in_lk` вычисляется backend.
| Компонент | Файлы | Владеющая задача | Общий файл с | Не трогать без пометки |
|---|---|---|---|---|
| Subscription Offer State | миграция и модель `subscription_offer_states` | Состояние оффера подписки | — | Не менять из других задач без обновления Component Map |
| Subscriptions::OfferPresentationService | `Subscriptions::OfferPresentationService` | Состояние оффера подписки | — | Не изменять eligibility, GrowthPromo и point-scoped settings; сервис только использует их результаты |
| Subscription Offer API | routes/controllers для `/shop/api/subscription_offer/dismiss`, `/shop/api/subscription_offer/viewed`, расширение `profile/config` | Состояние оффера подписки | — | Не смешивать с frontend-логикой баннера/ЛК/push |

---

## Заметки агента

- Тип: **новая фича** — в репо нет `subscription_offer_states` / `OfferPresentationService`; не патч и не EXT → полный SBR.
- §5 `npx tsc --noEmit` — для Rails-бэкенда не применимо; канон проверки — `bin/rails test` (уточнить на `/spec`).
