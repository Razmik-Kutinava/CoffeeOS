# TASK_94: Повтор покупки из истории ЛК с one-click оплатой

**CBR:** #94 · **Дата intake:** 2026-09-19  
**Источник:** Google Doc Spec  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/lk_history_repeat_one_click/  
**Google Doc:** https://docs.google.com/document/d/19QWNuRirU9jGkzFMY7sXXQV8xFTf2oEq_u3Yf0fo-6w/edit  
**Расширяет:** [`TASK-PERSONAL-CABINET.md`](TASK-PERSONAL-CABINET.md)  
**Тип:** дополнительная задача (не патч Subtask 12)  
**Статус:** intake `[x]` · `/spec` `[x]` · REVIEW 2026-09-19 (G5 Fly после deploy) · **Патч 1 (2026-10-01)** — `/patch` `[x]` 2026-10-05 · ждёт `/sbr`

---

## Текст задачи (дословно) — Google Doc Spec

TASK_94: Повтор покупки из истории ЛК с one-click оплатой
Расширяет: docs/operations/milestones/veha_2/requirements/customer_tasks/TASK-PERSONAL-CABINET.md
Основание: read-only аудит ЛК → Quick Repeat → inline payment от 2026-09-18
ВАЖНО: исходный TASK-PERSONAL-CABINET Subtask 12 сознательно фиксировал кнопку «ПОВТОРИТЬ» без бизнес-логики. Эта задача не является патчем исходного поведения, а добавляет новый пользовательский сценарий.
Бизнес-цель: дать пользователю возможность повторить покупку непосредственно из истории заказов ЛК с использованием существующего one-click payment flow, без копирования отдельной платежной реализации и без изменения стандартного checkout.
1. Карта интеграций — затронуто
Новые внешние интеграционные контракты не требуются.
Используются существующие внутренние контуры:
История ЛК → существующий Order → repeat/create order → widget payment → payment status → active order
Существующий payment API и контракт widget_init не изменять.
Существующий Quick Repeat payment flow использовать как источник поведения:
POST /orders
POST /payments/widget_init
GET /payments/status/:orderId
Новые внешние интеграции, ОФД и изменение payment/webhook-контрактов не входят в задачу.
2. Карта компонентов
Затрагиваемые компоненты
app/frontend/routes/Profile.svelte
app/frontend/routes/OrderReceipt.svelte
существующий repeat/payment flow:
createRepeatInlineOrder.js
widgetRepeatPayFlow.js
repeatInlinePayUiStore.js
при необходимости — тонкий адаптер между данными исторического Order и форматом существующего repeat flow.
Общий файл с другой задачей
Да.
Граница:
Order → /orders/active → ActiveOrdersPresenter → OrderStatusSheet
является общим контуром стандартного checkout, Quick Repeat и других сценариев создания заказов.
В этой задаче запрещено менять общую семантику active orders/status model.
cartSheetStore.js также является общим файлом. Его существующая логика clearCartAfterSuccessfulPay не должна изменяться ради данного сценария.
Новый компонент
Не требуется, если существующих экспортированных функций достаточно.
Не создавать второй payment flow специально для ЛК.
3. Текущее поведение
По факту:
В каноническом ЛК #/profile история заказов находится в Profile.svelte.
Кнопка shop-lk-repeat-btn сейчас вызывает openReceipt(order.id):
app/frontend/routes/Profile.svelte:105–107.
openReceipt переводит пользователя на /order/:id/receipt:
Profile.svelte:50–52.
На OrderReceipt.svelte кнопка shop-order-repeat-stub имеет пустой handler:
OrderReceipt.svelte:38–40, 108–110.
Создание нового Order или запуск payment flow из этого handler отсутствуют.
Существующий Quick Repeat уже имеет экспортированные:
createRepeatInlineOrder(item, { api, quantities })
runRepeatWidgetPayFlow(...)
Их фактическая оркестрация сейчас находится внутри RepeatSection.onPayCardClick.
PersonalAccount.svelte содержит попытку вызвать createRepeatInlineOrder, но вызов не соответствует фактической сигнатуре функции:
PersonalAccount.svelte:64–69 и createRepeatInlineOrder.js:18.
Источник фактов: read-only аудит от 2026-09-18.
4. Scope
Разрешено
изменить обработчик «Повторить» в каноническом ЛК;
реализовать получение/передачу состава выбранного исторического заказа в существующий repeat flow;
создать новый Order на основании выбранного исторического заказа;
запустить существующий one-click payment flow;
подключить существующий inline payment UI/FSM;
обеспечить отображение состояния оплаты пользователю;
обеспечить успешное завершение оплаты и отображение созданного заказа через существующий order-status контур;
добавить/изменить тесты сценария ЛК;
при необходимости создать тонкий reusable adapter для передачи исторического Order в существующий repeat flow.
Запрещено
менять стандартный checkout;
менять Checkout.svelte ради этого сценария;
менять контракт /payments/widget_init;
менять контракт /payments/status/:orderId;
создавать отдельную реализацию T-Bank payment для ЛК;
менять ОФД;
менять webhook/payment contracts;
менять критерии active order;
менять OrderStatusSheet / orderStatusSheet.js для решения задачи ЛК;
менять CartSheet и его существующее поведение;
менять hasActiveOrder gate Quick Repeat;
возвращать удалённые Quick Repeat UI-элементы;
менять Telegram/email feedback;
менять auth/routing за пределами необходимого маршрута сценария;
изменять стандартную оплату checkout.
Защитная граница
Обязательный тест должен доказать, что добавление repeat из ЛК не изменяет поведение стандартного checkout.
5. Gherkin
Subtask 1: Повторить заказ из истории ЛК
Given: пользователь авторизован и в истории ЛК отображается ранее созданный заказ
When: пользователь нажимает «Повторить» у выбранного заказа
Then: запускается сценарий повторной покупки именно выбранного заказа, а не только переход на экран просмотра его деталей.
Subtask 2: Создать новый заказ из исторического заказа
Given: пользователь инициировал повтор ранее созданного заказа
When: система формирует повторную покупку
Then: создаётся новый Order с составом и параметрами выбранного исторического заказа; исходный исторический Order не изменяется.
Subtask 3: Использовать существующий one-click payment flow
Given: новый Order для повторной покупки создан
When: пользователь выбирает/подтверждает one-click оплату
Then: используется существующий Quick Repeat / widget payment flow, а не отдельная реализация оплаты для ЛК.
Subtask 4: Показывать пользователю PROCESSING
Given: one-click payment запущен
When: банк обрабатывает платеж
Then: основная кнопка оплаты заблокирована и отображает текущее состояние обработки согласно существующему inline payment UX.
Subtask 5: Отображать результат успешной оплаты
Given: polling получил CONFIRMED
When: payment flow завершается
Then: пользователь видит успешное состояние оплаты и созданный Order становится доступен через существующий active-order/status контур.
Subtask 6: Обработать отказ оплаты
Given: payment flow получил REJECTED или CANCELED
When: платеж завершился отказом
Then: пользователь получает существующее состояние ошибки/fallback и возможность повторить оплату или выбрать другой способ оплаты согласно существующему payment flow.
Subtask 7: Не смешивать исторический Order и текущую корзину
Given: пользователь повторяет конкретный заказ из истории
When: создаётся новый Order
Then: состав повторной покупки формируется из выбранного исторического заказа, а не из случайного текущего состояния корзины.
Subtask 8: Не менять стандартный checkout
Given: пользователь выполняет обычную покупку через checkout
When: выполняется стандартный checkout payment flow
Then: поведение стандартного checkout остаётся неизменным.
Subtask 9: Защитить active-order contour
Given: повторная покупка успешно оплачена
When: Order становится активным
Then: используется существующий /orders/active и существующая модель OrderStatusSheet без изменения её критериев и контракта.
6. TDD-проверка: команды
До реализации:
npm test -- --runInBand
bundle exec rails test

Целевые тесты должны покрывать:
ЛК → Repeat → создание нового Order
ЛК → Repeat → one-click payment
ЛК → Repeat → PROCESSING
ЛК → Repeat → CONFIRMED
ЛК → Repeat → REJECTED/CANCELED
ЛК → Repeat → исходный исторический Order не изменён
ЛК → Repeat → composition берётся из выбранного Order
standard checkout → regression protection

После реализации:
npm test -- --runInBand
bundle exec rails test
npx tsc --noEmit

Дополнительно выполнить ручную проверку:
Profile → история → Повторить → one-click payment → PROCESSING → результат → active order.
DoD:
«Повторить» в каноническом #/profile выполняет реальный repeat сценарий;
создаётся новый Order;
используется существующий Quick Repeat/payment flow;
payment status виден пользователю во время обработки;
исходный Order не изменяется;
стандартный checkout не изменён;
targeted + regression tests зелёные;
COMPONENT_MAP.md изменяется только после Review и зелёных тестов.

---

## Патч 1: 2026-10-01

**Тип:** ПАТЧ (Subtask 5, 6 были в Gherkin — код не соответствует уточнённому сценарию) · **/patch:** 2026-10-05  
**Источник:** тот же Google Doc, секция «Патч 1: 2026-10-01»

### Аудит (2026-10-05, без правок кода)

| Пункт | Факт | Файл:строка |
|---|---|---|
| CONFIRMED в ЛК | flow возвращает `INLINE_SUCCESS_LABEL` + `resetAfterMs`; навигации нет — пользователь остаётся на `#/profile` / `#/order/:id/receipt` | `widgetRepeatPayFlow.js:151-161` · `historyRepeatAdapter.js:139-160` |
| Таймеры после CONFIRMED | `setTimeout(resetRepeatInlinePayUi, resetAfterMs)` живёт после успеха | `historyRepeatAdapter.js:157-159` |
| REJECTED/CANCELED в ЛК | в store пишутся `showFallbackMethods`/`showRetry`/`savedCards`, но `Profile`/`OrderReceipt` их не рендерят — только текст ошибки | `historyRepeatAdapter.js:139-148` · `Profile.svelte:144-146` · `OrderReceipt.svelte:65-69, 170-173` |
| Существующий fallback-экран | `openRepeatPaymentSheet` → `#/checkout` + `PaymentMethodsSheet` (повтор / другая карта / новая карта / СБП); корзина уже содержит состав повтора — `addToCart` не дублируется | `openRepeatPaymentSheet.js:24-52` · `historyRepeatAdapter.js:71-78` |
| Вызов fallback сейчас | только ветка `openPaymentSheet` (нет карт), и берёт `items[0]` | `historyRepeatAdapter.js:149-156` |
| Главный экран статусов | `#/` + `OrderStatusSheet` (`/orders/active`); checkout приходит туда через `/payment-result` → auto `#/` (TASK_91), Quick Repeat уже на `#/` | `Checkout.svelte:508` · `PaymentResult.svelte:139,149` |

**Карта:** `Profile`, `OrderReceipt`, `historyRepeatAdapter`, `widgetRepeatPayFlow`, `repeatInlinePayUiStore` — строки есть (`COMPONENT_MAP.md`), общая граница `OrderStatusSheet` / `cartSheetStore` / `Checkout` — «не менять ради TASK_94».

### Трактовка для билда (по аналогии с существующими контурами)

1. **CONFIRMED → `#/` напрямую** (как Quick Repeat), не через `/payment-result` — иначе ЛК-повтор получит email-шаг checkout (#71), которого нет в Quick Repeat.
2. **REJECTED/CANCELED → существующий `openRepeatPaymentSheet`** (`#/checkout` + `PaymentMethodsSheet`) — это и есть существующий «экран оформления/оплаты» с повтором / другой картой / новой картой / СБП; `Checkout.svelte` не менять. Не `#/`.

### Текст патча (дословно) — Google Doc

Патч 1: 2026-10-01

Основание: уточнение сценария ЛК → Repeat → one-click payment; в исходном TASK_94 успешное завершение уже связано с "active-order/status" контуром (Subtask 5, 9), а ошибка — с существующим fallback (Subtask 6), но конечное пользовательское состояние и граница навигации явно не зафиксированы.

Расхождение

Subtask 5

Given: пользователь запустил повтор покупки из истории ЛК и оплатил созданный Order через существующий one-click payment flow.
When: polling получает "CONFIRMED" и платёж успешно завершён.
Then: созданный Order становится активным и пользователь должен оказаться на главном экране с отображением статуса активного заказа через существующий "/orders/active" / "OrderStatusSheet" контур.

По исходному сценарию зафиксировано только:

««пользователь видит успешное состояние оплаты и созданный Order становится доступен через существующий active-order/status контур».»

Не зафиксировано обязательное пользовательское завершение сценария: после успешной оплаты пользователь не должен оставаться на экране оформления/повтора, а должен перейти в существующий главный экран со статусами заказа.

Subtask 6

Given: payment flow получил "REJECTED" или "CANCELED".
When: платёж завершился отказом.
Then: пользователь должен остаться в существующем экране оформления/оплаты, где доступен существующий fallback: повторить оплату, выбрать другую сохранённую карту, добавить новую карту или использовать СБП.

Исходный сценарий фиксирует только возможность повторить оплату/выбрать другой способ, но не фиксирует, что при неуспешной оплате пользователь не должен уходить на главный экран статусов и должен сохранить доступ к существующему экрану выбора/изменения способа оплаты.

Исправленный сценарий

- [ ] **Subtask 5 (patch v1): Успешная оплата → главный экран статусов**

Given: пользователь инициировал повтор покупки из истории ЛК, создан новый Order и запущен существующий one-click payment flow.
When: polling получает финальный "CONFIRMED" и оплата успешно завершена.
Then:

1. все таймеры и polling текущего payment flow завершаются;
2. созданный Order становится активным через существующий active-order контур;
3. пользователь покидает экран оформления/повторной оплаты и оказывается на существующем главном экране со статусами заказа;
4. статус созданного Order отображается через существующий "/orders/active" / "OrderStatusSheet" контур;
5. не создаётся отдельная реализация отображения статуса или отдельный active-order механизм для ЛК.

- [ ] **Subtask 6 (patch v1): Неуспешная оплата → остаться в оформлении**

Given: пользователь выполняет повтор покупки из истории ЛК и payment flow получает "REJECTED" или "CANCELED".
When: платёж завершается отказом.
Then:

1. пользователь остаётся в существующем экране оформления/оплаты;
2. текущий Order не считается успешно оплаченным и не переводится в active-order контур как оплаченный;
3. сохраняется существующий fallback payment flow;
4. пользователь может повторить оплату;
5. пользователь может выбрать другую сохранённую карту;
6. пользователь может добавить/использовать другую карту;
7. пользователь может выбрать СБП;
8. не выполняется переход на главный экран статусов как результат неуспешной оплаты.

Защитная граница

Этот патч не вводит новый payment flow и не меняет существующий механизм навигации.

Успешный сценарий должен использовать существующий контур:

"repeat payment → successful payment → existing active Order → /orders/active → existing OrderStatusSheet / главный экран статусов"

Неуспешный сценарий должен использовать существующий контур:

"repeat payment → REJECTED/CANCELED → existing payment error/fallback → экран оформления → повтор / другая карта / СБП"

Не трогать

См. исходный "TASK_94" и "COMPONENT_MAP.md".

Не изменять:

- стандартный checkout и его payment flow;
- существующий Quick Repeat payment flow;
- "/payments/widget_init";
- "/payments/status/:orderId";
- критерии создания/активации Order;
- "/orders/active";
- "OrderStatusSheet" и его существующую семантику;
- "cartSheetStore";
- существующий fallback выбора способа оплаты;
- SBP flow;
- T-Bank payment API;
- webhook/payment contracts;
- навигацию стандартной покупки вне сценария ЛК → Repeat;
- создавать отдельный механизм перехода на экран статусов только для ЛК.

Scope

Разрешено:

- уточнить/исправить только связывание результата существующего repeat payment flow с уже существующим active-order/status контуром;
- обеспечить переход пользователя на существующий главный экран со статусами после "CONFIRMED";
- сохранить пользователя на существующем экране оформления/оплаты при "REJECTED"/"CANCELED";
- добавить targeted tests на оба перехода;
- при необходимости исправить только orchestration/navigation boundary, непосредственно связывающую существующий payment result с существующим экраном.

Запрещено:

- создавать новый экран статусов;
- создавать новый payment flow;
- менять критерии "active order";
- менять "OrderStatusSheet";
- менять стандартный checkout;
- менять payment API;
- переносить fallback-логику в новый компонент;
- менять существующую механику выбора карты/СБП;
- делать внешний redirect;
- менять поведение других сценариев оплаты.

TDD-проверка

До реализации добавить failing-тесты:

1. "ЛК → Repeat → one-click payment → CONFIRMED"
   - созданный Order становится активным;
   - пользователь оказывается на существующем главном экране со статусами;
   - используется существующий active-order/status контур.

2. "ЛК → Repeat → one-click payment → REJECTED"
   - пользователь остаётся на экране оформления/оплаты;
   - доступен существующий fallback;
   - доступны смена/добавление карты и СБП согласно существующему payment UI.

3. "ЛК → Repeat → one-click payment → CANCELED"
   - те же гарантии, что для "REJECTED".

4. Regression:
   - успешная обычная оплата checkout по-прежнему приводит к существующему экрану статусов;
   - неуспешная обычная оплата сохраняет существующий checkout fallback;
   - Quick Repeat вне ЛК не изменяет своё поведение.

После реализации выполнить targeted tests, frontend/backend regression tests и "npx tsc --noEmit".

Патч считается закрытым только после Review и зелёных тестов.
