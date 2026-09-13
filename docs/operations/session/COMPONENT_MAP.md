# COMPONENT_MAP.md — карта компонентов: shop / активные заказы на витрине

**Стек зоны:** Svelte (не React). Rails-partials для статусного виджета не найдены.  
**Обновление:** тронул компонент из этой зоны → правь эту таблицу в том же PR/патче.  
**Чтение агентом:** on-demand — **не** на каждом `/start`. Читать только если задача трогает зону (CartSheet / OrderStatus* / active orders / GuestOrder*).  
**Примечание:** `.cursor/tasks/` в репозитории отсутствует — колонка «Задача-владелец» не заполнена; владение восстанавливается по номеру PR из коммитов.

| Компонент | Файл | Назначение | Связи | Последние PR | Не трогать без пометки |
|---|---|---|---|---|---|
| CartSheet | app/frontend/components/CartSheet.svelte | Хост-контейнер; монтирует OrderStatusSheet; gate hasActiveOrder | → OrderStatusSheet; store hasActiveOrder, statusWidgetUiVisible; cartSheetThresholds | #80, #67, #63 | Высота STATUS_IN_SHEET_EXTRA_VH — общая с cartSheetThresholds |
| OrderStatusSheet | app/frontend/components/OrderStatusSheet.svelte | Sticky-панель активных заказов: GET /orders/active, Cable, poll, dismiss, cancel-modal | → ActiveOrdersAccordion, OrderCancelModal; множество lib | #63, #35 | Родитель ActiveOrdersAccordion — правки в дочернем компоненте влияют на этот файл |
| ActiveOrdersAccordion | app/frontend/components/ActiveOrdersAccordion.svelte | Поведение крестика (dismiss) в статусной шторке | Общий файл с: Восстановление чека | #83 | Блок чека / receiptView; изменения только в `aoa__dismiss` (139–150) |
| OrderActionButtons | app/frontend/components/OrderActionButtons.svelte | До 2 CTA (cancel/push/wallet/chat/tips/subscription) | → orderStatusCtaMachine, orderActionButtons, subscriptionOfferCta | #77, #41 | — |
| OrderCancelModal | app/frontend/components/OrderCancelModal.svelte | Confirm-модалка отмены accepted-заказа | Пропсы из OrderStatusSheet/OrderStatus | — | — |
| OrderStatus (route) | app/frontend/routes/OrderStatus.svelte | Полноэкранный #/order/:id: статус, progress, CTA, cancel | Cable, orderStatusProgress, orderStatusCtaMachine, OrderCancelModal | #77 | Отдельный маршрут — не путать со sticky-виджетом |
| orderStatusSheet.js | app/frontend/lib/orderStatusSheet.js | Поведение крестика (dismiss) в статусной шторке | Общий файл с: Восстановление чека | #83 | Блок чека / receiptView; изменения только в `dismissOrder` / `refreshMode` (119–132) |
| activeOrdersAccordion.js | app/frontend/lib/activeOrdersAccordion.js | Стейт accordion; receiptView — хелпер чека, не используется в текущем .svelte | OrderStatusSheet, ActiveOrdersAccordion | #35, #36 | Требует аудита: почему receiptView не подключён |
| shopOrderCable.js | app/frontend/lib/shopOrderCable.js | Подписка ActionCable Shop::GuestOrderChannel + retry | OrderStatusSheet, OrderStatus | #35 | — |
| orderStatusProgress.js | app/frontend/lib/orderStatusProgress.js | Маппинг Order.status → шаги progress/ETA | activeOrdersAccordion, OrderStatus | B1.1, b2.1 | — |
| orderStatusCtaMachine.js | app/frontend/lib/orderStatusCtaMachine.js | CTA-машина по status/OS/can_cancel/push/subscription | OrderActionButtons, OrderStatus | #35, #77 | — |
| orderStatusNotifyActions.js | app/frontend/lib/orderStatusNotifyActions.js | Wallet download, push subscribe, open receipt toggle | ActiveOrdersAccordion, OrderStatus | #81 | Есть "open receipt toggle" — уточнить связь с receiptView |
| frequentRepeatStore.js | app/frontend/lib/frequentRepeatStore.js | Store hasActiveOrder; gate Repeat в CartSheet | CartSheet, OrderStatusSheet, RepeatSection | — | — |
| shopGuestSession.js | app/frontend/lib/shopGuestSession.js | reconnect_token / last order id | OrderStatusSheet, OrderStatus, Cable | #66 | — |
| OrdersController#active/cancel/wallet_pass | app/controllers/shop/api/orders_controller.rb | GET orders/active, POST cancel, GET wallet_pass | ActiveOrdersPresenter, GuestOrderCancellationService | #82 | — |
| ActiveOrdersPresenter | app/services/shop/active_orders_presenter.rb | JSON активных заказов: items/mods/totals/can_cancel | OrdersController#active | #41, #36 | items/mods в JSON уже отдаются backend'ом — фронт их не рендерит |
| GuestOrderChannel | app/channels/shop/guest_order_channel.rb | Cable-подписка гостя на заказ, presence | OrderReadyPresence, GuestOrderBroadcaster | — | — |
| GuestOrderBroadcaster | app/services/shop/guest_order_broadcaster.rb | Broadcast status_changed (+ push/wallet/cascade) | GuestOrderChannel | #82 | — |
| GuestOrderCancellationService | app/services/shop/guest_order_cancellation_service.rb | Серверная отмена + broadcast | OrdersController#cancel | — | — |
| GuestOrderReconnect | app/services/shop/guest_order_reconnect.rb | Токен/bind для Cable reconnect | Channel, FE session | — | — |
| OrderReadyPresence | app/services/shop/order_ready_presence.rb | online/offline флаг заказа для cascade | GuestOrderChannel, Broadcaster | — | — |

**Маршруты API зоны:** GET /shop/api/orders/active · POST /shop/api/orders/:id/cancel · GET /shop/api/orders/:id/wallet_pass

**Известные дыры (требуют точечного аудита перед следующей задачей):**
1. Чек (receiptView) существует как хелпер, но не рендерится в ActiveOrdersAccordion.svelte.
2. ActiveOrdersPresenter уже отдаёт items/modifiers/totals в JSON — backend, вероятно, готов.
3. Крестик (×) — находится в ActiveOrdersAccordion.svelte, поведение не проверено.

**Известный технический долг (вне этой зоны, зафиксировано отдельно):**  
`todo-email-collection.md` и `todo-personal-cabinet.md` существуют параллельно основному `todo.md`, нарушая правило «один живой файл» (`coffeeos-context-hygiene.mdc`). Не трогать без отдельной задачи на очистку.

---

## Как обновлять (БЛОК 4 после Review)

Только когда тесты зелёные **и** владелец принял результат; задача **главная** для этой зоны (новый/удалённый/переименованный компонент или смена связей/стейта).

Промпт (вставить фрагмент БЛОКА 4 из задачи):

```
Обнови docs/operations/session/COMPONENT_MAP.md.

Вставь/замени в таблице строку(и):

[фрагмент БЛОКА 4]

Правила:
Если компонент с таким названием уже есть в таблице — замени его строку целиком, не создавай дубликат.
Если компонента ещё нет — добавь новую строку в конец таблицы.
Остальной файл (заголовок, известные дыры, тех.долг) не трогать.
Это правка документации, не код — тестов не требуется.
Закоммить отдельным маленьким коммитом: "docs: update COMPONENT_MAP — [Название компонента]"
```

Не главная задача / нет смены строки карты → карту не трогать.
