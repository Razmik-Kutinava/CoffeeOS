# TASK_84-RECEIPT-DISPLAY-EXT: Восстановление фактического отображения состава чека в ActiveOrdersAccordion

**ID заказчика:** TASK_84-RECEIPT-DISPLAY-EXT · **семья:** TASK_84 · **Дата intake:** 2026-09-21  
**Источник:** Google Doc  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/active_orders_receipt_display_restore/  
**Google Doc:** https://docs.google.com/document/d/13Msfo8hDhUXHHB3NoKhMQvrPxQMpvlKctvFDOkr7aEI/edit  
**Расширяет:** [`TASK-84-status-sheet-receipt-restore.md`](TASK-84-status-sheet-receipt-restore.md)  
**Тип:** дополнительная задача (EXT)  
**Статус:** **REVIEW** 2026-09-21 · push/CI · G5 Fly после deploy

---

## Текст заказчика (дословно) — Google Doc

# TASK: Восстановление фактического отображения состава чека в ActiveOrdersAccordion

**Расширяет:** `docs/operations/milestones/veha_2/requirements/customer_tasks/TASK-84-status-sheet-receipt-restore.md`  
**Реверсирует:** `#35 / commit 7ab3f3e6` — `feat: #35 QA reopen … "status row without receipt"`

**Тип:** дополнительная задача

**Основание:** аудит регрессии текстового чека активных заказов от 2026-09-21.

## Бизнес-цель

Восстановить фактическое отображение состава чека внутри раскрытого активного заказа в PWA.

После раскрытия заказа пользователь должен видеть текстовый состав чека: позиции, модификаторы, количество, цены, скидки и финансовые итоги.

Функциональность должна работать на основе уже существующего `receiptView` и существующих данных `GET /shop/api/orders/active`.

Не изменять существующую механику статусов активного заказа, accordion, polling/Cable, отмены заказа и другие соседние сценарии.

## 1. Карта интеграций — затронуто / нет

### Затронуто

Frontend получает данные чека из существующего `GET /shop/api/orders/active`.

По результатам аудита backend уже отдаёт необходимые данные:

- `items`
- `name`
- `quantity`
- `price`
- `modifiers`
- `discount`
- `line_total`
- `subtotal`
- `total_amount`

Изменение backend-контракта не требуется.

### Не затронуто

Не изменять:

- `GET /shop/api/orders/active`
- `OrdersController#active`
- `ActiveOrdersPresenter`
- polling
- ActionCable
- reconnect
- push
- wallet
- cancel API

Граница задачи: frontend-восстановление фактического отображения существующего receipt.

## 2. Карта компонентов

### ActiveOrdersAccordion

**Файл:** `app/frontend/components/ActiveOrdersAccordion.svelte`

**Затронуто:** да.

Компонент уже содержит:

- вызов `receiptView(order)`;
- условие `{#if receipt}`;
- текстовую разметку receipt;
- CTA «Состав заказа».

Требуется устранить расхождение между текущим кодом и фактическим отображением receipt в последнем билде.

### activeOrdersAccordion

**Файл:** `app/frontend/lib/activeOrdersAccordion.js`

**Затронуто:** только если это потребуется для восстановления фактического пути раскрытия.

`receiptView(order)` уже существует и формирует:

- `lines`;
- `name`;
- `modifiers`;
- `quantity`;
- `price`;
- `discount`;
- `lineTotal`;
- `subtotal`;
- `discount`;
- `totalAmount`.

Реализацию `receiptView` не переписывать.

### orderStatusNotifyActions

**Файл:** `app/frontend/lib/orderStatusNotifyActions.js`

**Затронуто:** только при необходимости сохранить/восстановить существующий вызов `openOrderReceipt`.

Сигнатуру `openOrderReceipt` не менять.

### OrderStatusSheet

**Файл:** `app/frontend/components/OrderStatusSheet.svelte`

**Затронуто:** нет.

Не менять родительский state и режимы шторки ради этой задачи.

### Новый компонент

Не требуется.

Использовать существующие `ActiveOrdersAccordion` и `receiptView`.

## 3. Текущее поведение — факт

По результатам read-only аудита текущий HEAD уже содержит путь:

`row.expanded → receiptView(order) → receipt → {#if receipt} → текстовый receipt`

Факты:

- `ActiveOrdersAccordion.svelte:39` — вычисление `receipt`;
- `ActiveOrdersAccordion.svelte:261–286` — рендер текстового receipt;
- `activeOrdersAccordion.js:77–96` — `receiptView`;
- `active_orders_accordion_test.mjs:211–223` — source-contract проверки #84;
- `active_orders_receipt_test.rb:44–90` — backend-контракт данных.

При этом статический аудит не установил точную runtime-причину, почему в фактическом последнем билде текстовый блок не отображается.

Поэтому причина не считается установленной до воспроизведения проблемы тестом/сборкой.

Задача должна закрыть расхождение между текущим кодом и фактическим поведением.

## 4. Scope

### Разрешено

1. Проверить и восстановить фактический runtime-путь раскрытия receipt.
2. Исправлять только код, необходимый для того, чтобы при раскрытии заказа существующий `receiptView` приводил к отображению текстового блока.
3. Сохранить существующую структуру `receiptView`.
4. Сохранить отображение:
   - наименования;
   - модификаторов;
   - количества;
   - цены;
   - скидки;
   - итога позиции;
   - Subtotal;
   - Discount;
   - Total Amount.
5. Сохранить внутренний scroll receipt:
   - `max-height`;
   - `overflow-y: auto`.
6. Добавить или усилить тест, проверяющий фактическое наличие receipt после раскрытия.
7. Проверить сценарии:
   - один активный заказ;
   - два активных заказа;
   - раскрытие первого заказа;
   - переключение на второй заказ;
   - закрытие раскрытого заказа.
8. Сохранить правило: одновременно раскрыт максимум один receipt.
9. Сохранить отсутствие интерактивных элементов внутри `.aoa__receipt`.

### Запрещено

Не менять:

- реализацию `receiptView`;
- backend API;
- `ActiveOrdersPresenter`;
- `OrdersController#active`;
- `OrderStatusSheet` polling;
- ActionCable;
- reconnect;
- status/progress mapping;
- `OrderActionButtons`;
- cancel-modal;
- `aoa__dismiss`;
- push recovery;
- wallet;
- subscription CTA;
- TASK_91;
- TASK_94;
- #77;
- #81;
- #83;
- #90;
- #92.

Не возвращать старую функциональность, удалённую #35, кроме согласованного состава чека из #84.

Не возвращать старый chevron #36.

## 5. Gherkin

### Subtask 1 — отображение receipt после раскрытия

- [ ] Given: PWA получила активный заказ с минимум одной позицией и финансовыми итогами
- [ ] When: пользователь нажимает существующий CTA «Состав заказа» / раскрывает заказ
- [ ] Then: раскрытый заказ отображает текстовый блок `.aoa__receipt`

### Subtask 2 — отображение позиции

- [ ] Given: активный заказ содержит позицию с `name`, `quantity`, `price` и `line_total`
- [ ] When: receipt раскрыт
- [ ] Then: текст чека содержит наименование позиции, количество, цену и итог позиции

### Subtask 3 — отображение модификаторов

- [ ] Given: позиция содержит один или несколько модификаторов
- [ ] When: receipt раскрыт
- [ ] Then: модификаторы отображаются текстом внутри receipt

### Subtask 4 — товар без модификаторов

- [ ] Given: позиция не содержит модификаторов
- [ ] When: receipt раскрыт
- [ ] Then: позиция отображается без ошибки и без пустого интерактивного блока модификаторов

### Subtask 5 — финансовые итоги

- [ ] Given: receipt содержит `subtotal`, `discount` и `total_amount`
- [ ] When: receipt раскрыт
- [ ] Then: отображаются Subtotal, Discount и Total Amount

### Subtask 6 — нулевая скидка

- [ ] Given: `discount = 0`
- [ ] When: receipt раскрыт
- [ ] Then: строка Discount отображается корректно и не ломает структуру receipt

### Subtask 7 — пустой items

- [ ] Given: активный заказ содержит `items = []`
- [ ] When: receipt раскрыт
- [ ] Then: компонент не падает и отображает доступные финансовые итоги без обращения к отсутствующей позиции

### Subtask 8 — только один раскрытый заказ

- [ ] Given: существуют активные заказы №1 и №2
- [ ] When: пользователь раскрывает заказ №1
- [ ] Then: receipt №1 отображается
- [ ] And: receipt №2 не отображается

### Subtask 9 — переключение между заказами

- [ ] Given: заказ №1 раскрыт
- [ ] When: пользователь раскрывает заказ №2
- [ ] Then: receipt №1 закрывается
- [ ] And: receipt №2 отображается
- [ ] And: одновременно отображается максимум один receipt

### Subtask 10 — закрытие раскрытого заказа

- [ ] Given: заказ раскрыт
- [ ] When: пользователь повторно активирует существующий toggle раскрытия
- [ ] Then: `activeExpandedOrderId` становится `null`
- [ ] And: receipt больше не отображается

### Subtask 11 — внутренний scroll

- [ ] Given: receipt содержит длинный список позиций
- [ ] When: пользователь прокручивает область receipt
- [ ] Then: прокручивается только содержимое receipt
- [ ] And: соседние заказы и внешняя шторка не получают дополнительного scroll

### Subtask 12 — receipt без интерактивных действий

- [ ] Given: receipt раскрыт
- [ ] When: компонент отрисован
- [ ] Then: внутри `.aoa__receipt` нет кнопок действий
- [ ] And: receipt остаётся текстовым представлением состава заказа

### Subtask 13 — runtime regression contract

- [ ] Given: компонент получает валидный активный заказ
- [ ] When: состояние заказа переводится в expanded через фактический пользовательский путь
- [ ] Then: DOM содержит `.aoa__receipt`
- [ ] And: DOM содержит текст хотя бы одной позиции из входных данных
- [ ] And: DOM содержит Total Amount

Обязательный критерий: тест должен проверять результат рендера, а не только наличие строки `receiptView(` в исходном файле.

## 6. Защитный тест для реверса #35

Исторически после #35 существовал защитный контракт, проверяющий отсутствие receipt.

После #84 этот тест был сознательно заменён на позитивный контракт восстановления receipt.

Требования:

- [ ] Не восстанавливать старый негативный тест #35.
- [ ] Не добавлять тест, требующий отсутствия receipt.
- [ ] Сохранить позитивный контракт #84.
- [ ] Добавить runtime regression test, проверяющий фактическое отображение receipt.
- [ ] Защитить систему от повторного исчезновения receipt именно позитивным тестом.

## 7. TDD-проверка: команды

### RED

Добавить тест, воспроизводящий фактический пользовательский путь:

`активный заказ → раскрытие → проверка DOM → текст позиции → Total Amount`

Проверка:

```bash
node --test test/javascript/active_orders_accordion_test.mjs
```

---

## Заметки агента

- Заголовок Google Doc был `TASK_94: …`, но тело: **Тип: дополнительная задача**, **Расширяет: TASK-84**. В CBR **#94** уже занят (`TASK_94` LK history repeat). По канону intake EXT → суффикс к ID родителя: **`TASK_84-RECEIPT-DISPLAY-EXT`**, не новый `#94`.
- Документ обрывается на секции RED (нет GREEN/DoD в источнике) — для SPEC достаточно Gherkin + scope.
- Патчей и вложенных доп.задач в доке нет; Subtask 1–13 = критерии приёмки.
