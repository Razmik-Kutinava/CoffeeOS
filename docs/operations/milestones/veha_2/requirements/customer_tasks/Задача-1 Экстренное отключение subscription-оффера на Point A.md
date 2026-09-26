# Задача-1: Экстренное отключение subscription-оффера на Point A

**Google:** https://docs.google.com/document/d/1h-ChIiU09TKAIWsZDjbEWfOgEzZNhmUdwQghDqHI3CY/edit  
**Артефакты:** `docs/operations/milestones/veha_2/artifacts/subscription_offer_eligibility/`

Бизнес-цель: Немедленно вернуть Point A в безопасное состояние, чтобы гость не видел CTA оформления подписки, если фактического экрана и backend billing подписки ещё нет.

## 1. Связь с картой интеграций
- **Затронутые сервисы из `@INTEGRATIONS.md`:** Нет.
- **Смежные модули, которые НЕЛЬЗЯ ломать:** `SubscriptionOfferEligibility`, сигналы вовлечённости, УК-переключатель, текущая CTA-логика заказа, pending-адаптер чаевых.
- **Архитектурное решение:** Изменяется только конфигурация `subscription_offer_settings`; кодовая реализация subscription-offer не меняется.

## 2. Разрешенный и Запрещенный Scope
- **Разрешено менять/создавать:**
  - данные `subscription_offer_settings` для Point A;
  - данные `subscription_offer_settings` других точек только если полный SELECT выявит `enabled = true` и `second_cta_mode = subscription`;
  - internal-документацию/командный чат для фиксации факта временного отката.
- **Строго запрещено менять:**
  - `orderStatusCtaMachine.js`;
  - `OrderStatus.svelte`;
  - `ActiveOrdersAccordion.svelte`;
  - `SubscriptionOfferEligibility`;
  - сигналы вовлечённости;
  - УК-переключатель;
  - backend billing и экран оформления подписки;
  - `INTEGRATIONS.md`;
  - любые иные настройки или данные, не относящиеся к данному откату.

## 3. Сценарии и Чек-лист (Gherkin)

- [x] **Subtask 1: Выполнить полный SELECT конфигурации subscription-офферов**
  - Given: В системе существует таблица `subscription_offer_settings`, потенциально содержащая настройки нескольких точек.
  - When: Выполняется полный SELECT по всем записям/`point_id`.
  - Then: Получен и зафиксирован список всех точек, у которых `enabled = true`, отдельно отмечены записи с `second_cta_mode = subscription`.

- [x] **Subtask 2: Откатить конфигурацию Point A**
  - Given: Для Point A установлены `enabled = true` и `second_cta_mode = subscription`.
  - When: Изменение выполняется через существующий admin API/UI.
  - Then: Конфигурация Point A переводится в безопасное состояние: `enabled = false` либо `second_cta_mode = tips`; прямой SQL в production не используется, если доступен безопасный административный путь.

- [x] **Subtask 3: Откатить другие точки с аналогичным риском**
  - Given: Полный SELECT выявил другие точки с `enabled = true` и `second_cta_mode = subscription`, которые не должны оставаться в таком состоянии.
  - When: Для каждой такой точки применяется решение `enabled = false` либо `second_cta_mode = tips`.
  - Then: Ни одна непреднамеренно включённая subscription-конфигурация не остаётся активной.

- [x] **Subtask 4: Проверить поведение CTA на Point A после отката**
  - Given: Конфигурация Point A уже переведена в безопасное состояние.
  - When: Eligible-гость с активным push доходит до статуса заказа `ready`.
  - Then: CTA-матрица не показывает "Оформить подписку" и не выполняет redirect на subscription stub; отображается ожидаемая CTA согласно выбранной конфигурации.

- [x] **Subtask 5: Проверить чаевые при откате на `tips`**
  - Given: Для Point A выбран вариант отката `second_cta_mode = tips`.
  - When: Гость находится на статусе `ready` и использует CTA чаевых.
  - Then: Pending-адаптер чаевых продолжает работать без изменений и без ошибок.

- [x] **Subtask 6: Зафиксировать временный откат**
  - Given: Откат и ручная проверка Point A завершены.
  - When: Результат фиксируется во внутренней документации или командном чате.
  - Then: Зафиксированы факт отката, затронутые точки и выбранный вариант конфигурации; `INTEGRATIONS.md` не изменяется.

## 4. Команды TDD-проверки
- **Запуск тестов:** Не применимо к изменению только production-конфигурации; обязательна ручная проверка CTA.
- **Проверка типов:** `npx tsc --noEmit`

## Патч 1: 22.09.2026

Основание: архитектурное решение «5. Экстренное отключение оффера на Point A».

### Расхождение

Subtask 2–3: исходный сценарий допускает два варианта безопасного отката — `enabled = false` либо `second_cta_mode = tips`.
По новому решению экстренный откат однозначно выполняется через `enabled = false`.
`second_cta_mode = tips` больше не используется как механизм экстренного отключения subscription-offer.

### Исправленный сценарий

- [x] **Subtask 2 (patch v2): Откатить конфигурацию Point A**
  - Given: Для Point A subscription-offer включён.
  - When: Выполняется экстренный откат.
  - Then: Конфигурация Point A переводится в безопасное состояние `enabled = false`.
  - And: `second_cta_mode` не используется как механизм экстренного отключения.

- [x] **Subtask 3 (patch v2): Откатить другие точки с аналогичным риском**
  - Given: Полный SELECT выявил другие точки с активным subscription-offer, которые не должны оставаться включёнными.
  - When: Выполняется экстренный откат.
  - Then: Для каждой такой точки устанавливается `enabled = false`.

- [x] **Subtask 5 (patch v2): Проверить поведение после отключения**
  - Given: Для Point A установлено `enabled = false`.
  - When: Eligible-гость доходит до статуса `ready`.
  - Then: Subscription CTA не показывается.
  - And: Redirect на subscription checkout не выполняется.
  - And: `tips` не восстанавливается как замена subscription CTA.

### Чек-лист повторного включения

1. После завершения тестов убедиться, что backend billing подписки и экран оформления находятся в рабочем состоянии.
2. Через существующий УК-переключатель включить subscription-offer для Point A: `enabled = true`.
3. Проверить Point A на eligible-сценарии.
4. Проверить открытие реального экрана оформления подписки.
5. Проверить, что повторное отключение через УК переводит Point A обратно в `enabled = false`.
6. Только после успешной проверки Point A расширять включение на другие точки.

### Не трогать

См. COMPONENT_MAP.md и исходный Scope Задачи-1:

1. `SubscriptionOfferEligibility`;
2. сигналы вовлечённости;
3. CTA state machine;
4. pending-адаптер чаевых;
5. backend billing;
6. экран оформления подписки;
7. `INTEGRATIONS.md`.

Экстренное отключение выполняется конфигурацией и не требует изменения кода.

### Scope

**Разрешено:**

1. изменить `subscription_offer_settings` для отключения оффера;
2. использовать `enabled = false` как единственный механизм экстренного отключения;
3. зафиксировать чек-лист повторного включения;
4. после тестов включить Point A через существующий УК-переключатель.

**Запрещено:**

1. использовать `second_cta_mode = tips` как механизм экстренного отключения;
2. изменять код subscription-offer;
3. изменять CTA state machine;
4. изменять `SubscriptionOfferEligibility`;
5. восстанавливать tips как альтернативу отключённому subscription-offer;
6. расширять включение на другие точки до успешной проверки Point A.
