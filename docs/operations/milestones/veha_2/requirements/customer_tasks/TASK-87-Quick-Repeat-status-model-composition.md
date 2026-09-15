# TASK_87: Quick Repeat — отображение заказа и состава в status model

**CBR:** #87 · **Дата intake:** 2026-09-15  
**Источник:** Google Doc + правка заказчика (чат)  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/quick_repeat_status_model_composition/  
**Google Doc:** https://docs.google.com/document/d/1sdkJYZzLgVKiUTWfZuKDkL8kSuBPRNFSRiEFDQsxGbo/edit?usp=drivesdk  
**Расширяет:** [`Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)  
**Статус:** Spec (Google) · intake `[x]` · ждёт `/spec`

---

## Текст заказчика (дословно) — правка

Задача по правкам:

7.1/ Тут видно, что к нашей этой задаче по статусам через автоплатеж по карте добавилось к статусу ещё из прошлой задачи ещё блок с корзиной купленой

(скрин: `artifacts/quick_repeat_status_model_composition/01_status_after_card_autopay_cart_block.png`)

---

## Текст задачи (дословно) — Google Doc Spec

TASK_87: Quick Repeat — отображение заказа и состава в status model

Расширяет: "docs/operations/milestones/veha_2/requirements/customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md"

Тип: дополнительная задача

Бизнес-цель: зафиксировать и реализовать корректное поведение заказа, созданного через Quick Repeat «оплатить в 1 клик», в статусной модели заказа, не изменяя поведение стандартного checkout вне явно указанного scope.

1. Карта интеграций — затронуто / нет

Затронуто: да.

Затрагивается существующий контур:

"Quick Repeat → создание Order → оплата → GET /orders/active → ActiveOrdersPresenter → OrderStatusSheet"

Интеграции с платёжным виджетом и существующий API создания заказа используются без изменения их внешнего контракта, если иное не будет явно зафиксировано в Gherkin.

"docs/operations/INTEGRATIONS.md" на этапе Spec не изменять.

2. Карта компонентов

Компоненты:

- "RepeatSection.svelte" — Quick Repeat UI и запуск one-click оплаты.
- "createRepeatInlineOrder.js" — создание заказа для Quick Repeat one-click.
- "widgetRepeatPayFlow.js" — платёжный flow Quick Repeat.
- "orders_controller.rb" — создание заказа и получение "/orders/active".
- "order_creator.rb" — создание "Order", включая "pending_payment" и deferred payment.
- "active_orders_presenter.rb" — представление активных заказов для status model.
- "orderStatusSheet.js" — состояние/загрузка активных заказов.
- "OrderStatusSheet.svelte" — отображение заказа в status model.
- "CartSheet.svelte" — общий host для Quick Repeat и OrderStatusSheet.
- "frequentRepeatStore.js" — состояние Quick Repeat и синхронизация с активным заказом.

Общий файл с другой задачей: да.

Граница: контур "Order → /orders/active → OrderStatusSheet" является общим с обычным checkout и другими сценариями создания мобильного заказа.

Не трогать поведение обычного checkout, если изменение не требуется непосредственно для выполнения сценария данной задачи.

Новый компонент: нет.

3. Текущее поведение (факт, не требование)

По результатам read-only аудита:

1. При нажатии Quick Repeat «оплатить в 1 клик» создаётся реальный "Order". На момент создания его статус — "pending_payment".
   
   "createRepeatInlineOrder.js:30–48"
   "order_creator.rb:198–203"

2. После успешной оплаты заказ переходит в состояние, попадающее в "/orders/active".
   
   "orders_controller.rb:154–160"

3. "/orders/active" не фильтрует заказ по признаку Quick Repeat/one-click.
   
   "orders_controller.rb:154–160"

4. "OrderStatusSheet" получает активные заказы через "/orders/active" и обновляет их при polling.
   
   "OrderStatusSheet.svelte:132–140, 196–210"
   "orderStatusSheet.js:203–209"

5. По ручному тесту текущего поведения:
   
   - Quick Repeat «1 клик» → заказ появляется в status model и его состав отображается как в корзине.
   - стандартный flow "главный экран → товар → корзина → checkout → оплата" → заказ не показывает такой состав в status model.

6. В исходном Gherkin Quick Repeat поведение появления заказа в status model и отображения его состава не было зафиксировано.

Исходный сценарий Subtask 11 описывает добавление сохранённых позиций в корзину, скрытие bottom sheet и success toast, но не контракт состава заказа в status model.

4. Scope

Разрешено

- Зафиксировать контракт поведения Quick Repeat one-click после успешной оплаты.
- Обеспечить корректное попадание созданного Quick Repeat-заказа в status model согласно Gherkin этой задачи.
- Зафиксировать корректное отображение состава именно Quick Repeat-заказа в status model.
- Обеспечить, чтобы состав соответствовал позициям, созданным Quick Repeat one-click, включая сохранённые настройки/кастомизации, если они входят в создаваемый заказ.
- Добавить/изменить тесты, необходимые для фиксации контракта:
  - Quick Repeat one-click → создан Order;
  - после успешной оплаты → Order доступен в active orders;
  - status model получает этот Order;
  - состав Order в status model соответствует составу, созданному Quick Repeat.
- Синхронизировать Quick Repeat и status model только в пределах описанного сценария.

Запрещено

- Изменять бизнес-логику стандартного checkout без отдельного Gherkin.
- Менять существующий контракт "/orders/active" для всех заказов только ради Quick Repeat.
- Убирать Quick Repeat-заказ из status model без отдельного требования.
- Менять критерии активного заказа ("accepted", "preparing" и связанные с ними статусы) без отдельного сценария.
- Возвращать удалённую общую кнопку Quick Repeat или ранее удалённый сценарий "+more".
- Менять платёжный flow T-Bank/widget вне необходимого для данного сценария.
- Изменять "CartSheet" или "OrderStatusSheet" таким образом, чтобы это меняло отображение/поведение обычных заказов без соответствующего тестового контракта.
- Использовать текущее различие с обычным checkout как основание для автоматического изменения обычного checkout.

Защитная граница общего контура

Для общего контура:

"Order → /orders/active → ActiveOrdersPresenter → OrderStatusSheet"

изменения должны быть покрыты тестами так, чтобы существующее поведение стандартного checkout не менялось неявно.

5. Gherkin

- [ ] Subtask 1: Quick Repeat one-click создаёт заказ
  
  Given пользователь находится в Quick Repeat и у сохранённого товара доступна кнопка «оплатить в 1 клик»
  When пользователь нажимает «оплатить в 1 клик» и успешно проходит оплату
  Then создаётся "Order", соответствующий выбранной сохранённой позиции и её кастомизациям.

- [ ] Subtask 2: Оплаченный Quick Repeat-заказ появляется в status model
  
  Given Quick Repeat one-click создал заказ и оплата успешно завершена
  When заказ получает статус, входящий в активные заказы
  Then заказ доступен через "/orders/active"
  And отображается в status model.

- [ ] Subtask 3: Status model показывает состав Quick Repeat-заказа
  
  Given оплаченный Quick Repeat-заказ отображается в status model
  When пользователь открывает/просматривает этот заказ в status model
  Then отображается состав заказа
  And состав соответствует позициям, созданным Quick Repeat one-click
  And применённые к позициям сохранённые кастомизации не теряются.

- [ ] Subtask 4: Состав не берётся из текущей корзины
  
  Given Quick Repeat-заказ уже создан и отображается в status model
  When состояние текущей корзины изменяется
  Then состав уже созданного заказа в status model не изменяется вслед за корзиной
  And status model отображает состав самого "Order", а не текущее состояние cart.

- [ ] Subtask 5: Защитить стандартный checkout
  
  Given пользователь оформляет заказ стандартным flow "главный экран → товар → корзина → checkout → оплата"
  When заказ создаётся и отображается в status model
  Then существующее поведение стандартного checkout сохраняется
  And данная задача не изменяет его отображение состава без отдельного требования.

- [ ] Subtask 6: Не менять границу активных заказов
  
  Given Quick Repeat-заказ находится в статусе, не входящем в текущий набор активных заказов
  When status model запрашивает "/orders/active"
  Then заказ не появляется в status model до перехода в активный статус.

6. TDD-проверка: команды

Перед Build:

npm test -- --runInBand

или фактическая проектная команда запуска frontend-тестов.

Backend:

bundle exec rails test

Точечные проверки после добавления тестов:

bundle exec rails test test/controllers/active_orders_test.rb
bundle exec rails test test/services/customer_frequent_products_service_test.rb

Frontend:

npm test -- --runInBand

Проверить отдельно существующие тесты:

- Quick Repeat one-click;
- "createRepeatInlineOrder";
- "/orders/active";
- "OrderStatusSheet";
- presenter состава заказа.

DoD

- [ ] Quick Repeat one-click после успешной оплаты появляется в status model согласно Gherkin.
- [ ] Status model показывает состав именно созданного Quick Repeat-заказа.
- [ ] Состав не зависит от последующего состояния текущей корзины.
- [ ] Есть тестовый контракт на Quick Repeat → active order → composition.
- [ ] Защитные тесты подтверждают отсутствие непреднамеренного изменения стандартного checkout.
- [ ] Все существующие тесты зелёные.
- [ ] "todo.md" содержит один актуальный SBR-блок для этой задачи.
- [ ] До Review "COMPONENT_MAP.md" не изменяется.
- [ ] После Review и зелёных тестов "COMPONENT_MAP.md" обновляется точечно: один файл = одна строка, без изменения «Назначения» на имя задачи.

---

## Заметки агента

- Правка **7.1** (чат 2026-09-15): после автоплатежа картой в status sheet виден интерактивный блок корзины («Удалить», ± qty, «Итого», CTA `+N₽`) — пересечение с прошлым Quick Repeat / cart-in-sheet, не read-only состав заказа.
- Скрин intake: `01_status_after_card_autopay_cart_block.png`.
- Связь с #84 (receipt restore) и status-inside-cart-sheet — уточнить на `/spec` (границы: состав Order vs cart UI).
