# TASK_84: Восстановление состава чека в статусной шторке — EXT

**CBR:** #84 · **Дата intake:** 2026-09-13  
**Источник:** Google Doc  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/status_sheet_receipt_restore/  
**Google Doc:** https://docs.google.com/document/d/1kPKIChfHZVVZ5Ib2FSNE-2NyWAaKYUwqo0y2pQEJ_9E/edit?usp=drivesdk

---

## Текст заказчика (дословно)

# TASK_84: Восстановление состава чека в статусной шторке — EXT

Бизнес-цель: Вернуть состав чека в статусную шторку активных заказов. Ранее чек был удалён по QA-решению, зафиксированному в документе «Интеграция статусной модели в компактную шторку PWA...» и реализованному коммитом `7ab3f3e6` («QA reopen compact status sheet — status row without receipt»). Продуктовое решение пересмотрено: пользователь должен снова иметь возможность открыть и просмотреть состав заказа непосредственно в статусной шторке через CTA «Состав заказа».

Расширяет: `docs/operations/milestones/veha_2/requirements/customer_tasks/Мульти-статусная шторка активных заказов с просмотром состава чека.md`.

Реверсирует: QA-решение об удалении чека из компактной статусной шторки.

## 1. Связь с картой интеграций

- **Затронутые сервисы из `@INTEGRATIONS.md`:** Нет.
- **Смежные модули, которые НЕЛЬЗЯ ломать:** логика dismiss активных заказов, обработка `aoa__dismiss`, `orderStatusSheet.js`, включая `dismissOrder` и `refreshMode`.

## 2. Связь с картой компонентов

- **Затронутые компоненты из `@COMPONENT_MAP.md`:** `ActiveOrdersAccordion`.
- **Общий файл с другой задачей:** Да — с задачей «Поведение крестика (dismiss)». Обе задачи изменяют `app/frontend/components/ActiveOrdersAccordion.svelte`. Текущая задача владеет только изменениями, связанными с блоком чека и CTA «Состав заказа» после `meta/progress/CTA`. Логика `aoa__dismiss` и обработчик `×` принадлежат задаче «Поведение крестика (dismiss)» и не должны изменяться в рамках текущей задачи.
- **Новый компонент (не в карте):** Нет.

## 3. Разрешенный и Запрещенный Scope

- **Разрешено менять/создавать:**
  - `app/frontend/components/ActiveOrdersAccordion.svelte` — восстановить рендер блока чека и подключить CTA «Состав заказа», не изменяя `aoa__dismiss`.
  - `app/frontend/lib/activeOrdersAccordion.js` — использовать существующий `receiptView`; реализацию самой функции не изменять.
  - `app/frontend/lib/orderStatusNotifyActions.js` — подключить существующий `openOrderReceipt` к CTA; реализацию существующего обработчика не переписывать без необходимости.
  - `test/javascript/active_orders_accordion_test.mjs` — изменить тестовый участок строк `211–223`, который запрещает вызов `receiptView`, поскольку данный запрет фиксирует отменяемое QA-решение.

- **Строго запрещено менять:**
  - `app/frontend/components/ActiveOrdersAccordion.svelte:139–150` — `aoa__dismiss` и обработчик `×`, поскольку этот участок принадлежит задаче «Поведение крестика (dismiss)».
  - `orderStatusSheet.js` — `dismissOrder`, `refreshMode` и любую другую логику dismiss/status sheet, не относящуюся к восстановлению чека.
  - Реализацию `receiptView` в `app/frontend/lib/activeOrdersAccordion.js`.
  - Создание нового `todo-[feature].md`; текущая работа отслеживается только в `docs/operations/session/todo.md`.

## 4. Сценарии и Чек-лист (Gherkin)

- [ ] **Subtask 1: Снять защитный запрет на receiptView**
  - Given: в `test/javascript/active_orders_accordion_test.mjs:211–223` существует тест, запрещающий вызов `receiptView`
  - When: выполняется восстановление состава чека
  - Then: тест-запрет удалён или переписан на позитивную проверку использования/рендера `receiptView`, после чего тестовый набор не блокирует восстановление чека

- [ ] **Subtask 2: Восстановить рендер состава чека**
  - Given: строка активного заказа находится в состоянии `row.expanded = true`
  - When: `ActiveOrdersAccordion.svelte` рендерит строку заказа
  - Then: после блока `meta/progress/CTA` отображается состав чека, сформированный через существующий `receiptView(order)`, без изменения реализации `receiptView`

- [ ] **Subtask 3: Проверить структуру отображаемого чека**
  - Given: `receiptView(order)` возвращает состав заказа с позициями и итогами
  - When: блок чека отображается в развёрнутой строке
  - Then: пользователь видит наименование позиции, модификаторы, количество, цену, скидку и итоговую сумму к оплате в существующей модели данных

- [ ] **Subtask 4: Восстановить CTA «Состав заказа»**
  - Given: активный заказ находится в статусе `accepted`, `paid` или `preparing`
  - When: пользователь нажимает CTA с `LABELS.receipt`
  - Then: вызывается существующий `openOrderReceipt`, который использует `toggleExpandedOrder`, а состояние отображения состава заказа изменяется без изменения логики dismiss

- [ ] **Subtask 5: Проверить повторное открытие и закрытие чека**
  - Given: состав заказа открыт
  - When: пользователь повторно нажимает CTA «Состав заказа»
  - Then: состояние чека переключается через существующий `toggleExpandedOrder`, при этом состояние `aoa__dismiss` не изменяется

- [ ] **Subtask 6: Ограничить скролл длинного чека**
  - Given: заказ содержит количество позиций, превышающее доступную высоту блока чека
  - When: пользователь прокручивает состав заказа
  - Then: прокручивается только внутренний блок чека с `max-height` и `overflow-y: auto`, а статусная шторка и внешняя витрина не прокручиваются

- [ ] **Subtask 7: Проверить отсутствие регрессии dismiss**
  - Given: в `ActiveOrdersAccordion` присутствует восстановленный блок чека
  - When: пользователь взаимодействует с `aoa__dismiss` / `×`
  - Then: существующая логика dismiss продолжает работать без изменений; код dismiss, принадлежащий задаче «Поведение крестика (dismiss)», не модифицируется текущей задачей

## 5. Команды TDD-проверки

- **Запуск тестов:** `yarn test test/javascript/active_orders_accordion_test.mjs`
- **Проверка типов:** `yarn tsc` (если применимо к проекту)

## Восстановление состава чека в статусной шторке — EXT

### SBR
Текущая фаза: SPEC

### Файлы (ожидаемо)
- `app/frontend/components/ActiveOrdersAccordion.svelte`
- `app/frontend/lib/activeOrdersAccordion.js` — только использование существующего `receiptView`, без изменения реализации функции
- `app/frontend/lib/orderStatusNotifyActions.js` — подключение существующего `openOrderReceipt`
- `test/javascript/active_orders_accordion_test.mjs:211–223`

### Не ломать
- `aoa__dismiss` и обработчик `×` в `app/frontend/components/ActiveOrdersAccordion.svelte:139–150` — принадлежат задаче «Поведение крестика (dismiss)»
- `orderStatusSheet.js`, включая `dismissOrder` и `refreshMode`
- существующую реализацию `receiptView`
- существующую реализацию `openOrderReceipt`, если для подключения CTA не требуется её изменение
- отдельные `todo-[feature].md` файлы не создавать; единственный живой TODO — `docs/operations/session/todo.md`

### Проверка
- `yarn test test/javascript/active_orders_accordion_test.mjs`
- `yarn tsc` — если применимо к проекту

### DoD
- Защитный тест-запрет на `receiptView` в `test/javascript/active_orders_accordion_test.mjs:211–223` снят или заменён позитивным тестом.
- В `ActiveOrdersAccordion.svelte` восстановлен блок состава чека после `meta/progress/CTA`.
- Состав чека строится через существующий `receiptView(order)`.
- Отображаются наименование, модификаторы, количество, цена, скидка и итоговая сумма к оплате.
- CTA `LABELS.receipt` для `accepted/paid/preparing` подключён к существующему `openOrderReceipt`.
- Разворачивание/сворачивание состава выполняется через существующий `toggleExpandedOrder`.
- Длинный состав прокручивается внутри собственного блока, не двигая статусную шторку и витрину.
- `aoa__dismiss` / `×` не изменён.
- `orderStatusSheet.js` не изменён.
- Тесты проходят.

| Компонент | Файлы | Владеющая задача | Общий файл с | Не трогать без пометки |
|---|---|---|---|---|
| ActiveOrdersAccordion | `app/frontend/components/ActiveOrdersAccordion.svelte`; `app/frontend/lib/activeOrdersAccordion.js`; `app/frontend/lib/orderStatusNotifyActions.js`; `test/javascript/active_orders_accordion_test.mjs` | Восстановление состава чека в статусной шторке — EXT | Поведение крестика (dismiss) | В `ActiveOrdersAccordion.svelte` текущая задача изменяет только блок чека и CTA «Состав заказа» после `meta/progress/CTA`; `aoa__dismiss` / обработчик `×` не трогать |
