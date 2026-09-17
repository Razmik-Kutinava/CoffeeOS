# COMPONENT_MAP.md — карта компонентов: shop / активные заказы на витрине

**Стек зоны:** Svelte (не React). Rails-partials для статусного виджета не найдены.  
**Обновление:** тронул компонент из этой зоны → правь эту таблицу в том же PR/патче.  
**Чтение агентом:** on-demand — **не** на каждом `/start`. Читать только если задача трогает зону (CartSheet / OrderStatus* / active orders / GuestOrder*).  
**Примечание:** `.cursor/tasks/` в репозитории отсутствует — колонка «Задача-владелец» не заполнена; владение восстанавливается по номеру PR из коммитов.

| Компонент | Файл | Назначение | Связи | Последние PR | Не трогать без пометки |
|---|---|---|---|---|---|
| CartSheet | app/frontend/components/CartSheet.svelte | Хост-контейнер; монтирует OrderStatusSheet; gate hasActiveOrder | → OrderStatusSheet; store hasActiveOrder, statusWidgetUiVisible; cartSheetThresholds | #93, #91, #80, #67, #63 | Высота STATUS_IN_SHEET_EXTRA_VH — общая с cartSheetThresholds; phone-auth slim (`phoneAuthSlim` / `CHECKOUT_PHONE_AUTH_VH`) — #91; CTA/состав корзины вне phone-auth не трогать; монтирование статусной модели только на каталоге — не на payment-result (#93) |
| cartSheetStore | app/frontend/lib/cartSheetStore.js | Store корзины (items/total/mode); refresh; clear после успешной оплаты | → CartSheet; api DELETE /cart | #93, #91, #87 | `clearCartAfterSuccessfulPay` — после confirmed Quick Repeat (#87); не mutex status↔cart; `checkoutPhoneAuthActive` / `setCheckoutPhoneAuthActive` — только UI-флаг (#91); `isCartSheetRoute` — не добавлять `/payment-result` ради #93 |
| cartSheetThresholds | app/frontend/lib/cartSheetThresholds.js | Пороги и высоты cart sheet (peek/expanded/hidden; checkout pay-stack; phone-auth) | → CartSheet | #91 | `CHECKOUT_PHONE_AUTH_VH` / `CHECKOUT_PEEK_VH` / `CHECKOUT_PAY_STACK_VH` — не менять общие thresholds без доказанной нужды (#91) |
| shopWebViewLayout | app/frontend/lib/shopWebViewLayout.js | Visual viewport, keyboard inset, hide checkout CTA | → CartSheet | #91, #80 | `shouldHideCartCheckoutCta`: keyboard (#80) + `phoneAuthActive` (#91); keyboard-path не ломать |
| PhoneAuthWizard | app/frontend/components/PhoneAuthWizard.svelte | Wizard телефона: экран 1 → init_callcheck → PhoneAuthCodeStep | → PhoneAuthCodeStep; phoneAuthWizard; api /phone_otp/init_callcheck | #90, #89 | `init_callcheck` только с CTA «Продолжить»; lifecycle (visibility/pageshow) сюда не вешать (#90) |
| PhoneAuthCodeStep | app/frontend/components/PhoneAuthCodeStep.svelte | Экран 2: Callcheck poll → SMS PIN; resume после возврата из dialer | → phoneAuthCascade; api check_status/send_sms/verify_sms | #90, #89 | Resume poll на visibility/pageshow/pagehide/focus; без повторного `init_callcheck` (#90) |
| phoneAuthCascade | app/frontend/lib/phoneAuthCascade.js | Стейт-машина Callcheck→SMS; copy/hints; interpret poll; foreground action | → PhoneAuthCodeStep | #90, #89 | Copy «вернитесь» / «Проверяем номер»; `callcheckForegroundAction` — только poll, не init (#90) |
| Checkout | app/frontend/routes/Checkout.svelte | Маршрут #/checkout: корзина, phone wizard, handoff на оплату | → PhoneAuthWizard; PaymentMethodsSheet; cartSheetStore | #93, #91, #90, #89 | После verify: `onWizardVerified` → `openPaymentSheet` (#89/#90); `setCheckoutPhoneAuthActive(!phoneVerified)` — slim sheet (#91); `completePaySuccess` → `#/payment-result?status=ok` — не менять ради #93 |
| PaymentResult | app/frontend/routes/PaymentResult.svelte | Маршрут #/payment-result: success/fail/SBP waiting; email-сбор #71; переход на `#/` | → OrderSuccessEmailBlock; emailCollection; shopSbpPay; push `/` | #93, #71, #35 | `maybeAutoReturnToCatalog` только при `!askReceiptEmail` (#93); пока email-блок — без auto-redirect (#71); Continue → `handleEmailSkip` (#35); SBP waiting/recover не ломать (#79/#86) |
| PaymentMethodsSheet | app/frontend/components/PaymentMethodsSheet.svelte | Шторка способов оплаты / привязки карты | → Checkout; cartSheetStore openCheckoutPayStack | #90, #89 | Авто-open после auth — из Checkout; internals привязки/SBP не менять ради POSTCALL (#90) |
| OrderStatusSheet | app/frontend/components/OrderStatusSheet.svelte | Sticky-панель активных заказов: GET /orders/active, Cable, poll, dismiss, cancel-modal | → ActiveOrdersAccordion, OrderCancelModal; множество lib | #93, #63, #35 | Родитель ActiveOrdersAccordion — правки в дочернем компоненте влияют на этот файл; internals статуса не менять ради post-pay auto `#/` (#93) |
| ActiveOrdersAccordion | app/frontend/components/ActiveOrdersAccordion.svelte | Строка заказа: meta + progress + CTA + X; клик → #/order/:id | → OrderActionButtons; lib activeOrdersAccordion; orderStatusNotifyActions | #92, #81, #35, #77, #63, #84 | Recovery UI после push `denied` («Открыть настройки» / «Смотреть готовность») — #92; крестик (×) — #83; блок чека и CTA «Состав заказа» — #84; остальная разметка общая |
| OrderActionButtons | app/frontend/components/OrderActionButtons.svelte | До 2 CTA (cancel/push/wallet/chat/tips/subscription) | → orderStatusCtaMachine, orderActionButtons, subscriptionOfferCta | #77, #41 | — |
| OrderCancelModal | app/frontend/components/OrderCancelModal.svelte | Confirm-модалка отмены accepted-заказа | Пропсы из OrderStatusSheet/OrderStatus | — | — |
| OrderStatus (route) | app/frontend/routes/OrderStatus.svelte | Полноэкранный #/order/:id: статус, progress, CTA, cancel | Cable, orderStatusProgress, orderStatusCtaMachine, OrderCancelModal; supportChatAdapter; swNotificationActions | #94, #77 | Chat CTA → `openSupportChat` (не мёртвый `orderDeepLink`) — #94; tips deep link отдельно; не путать со sticky-виджетом |
| orderStatusSheet.js | app/frontend/lib/orderStatusSheet.js | Стейт peek/hidden/visible/dismiss, poll, cable apply | OrderStatusSheet, CartSheet | #93, #83 | Блок чека / receiptView; изменения только в `dismissOrder` / `refreshMode` (119–132); механизм статуса не менять ради post-pay auto `#/` (#93) |
| activeOrdersAccordion.js | app/frontend/lib/activeOrdersAccordion.js | Стейт accordion; receiptView — хелпер чека | OrderStatusSheet, ActiveOrdersAccordion | #35, #36, #84 | receiptView подключается задачей "Восстановление чека" (#84); саму функцию receiptView не менять, только вызывать |
| shopOrderCable.js | app/frontend/lib/shopOrderCable.js | Подписка ActionCable Shop::GuestOrderChannel + retry | OrderStatusSheet, OrderStatus | #35 | — |
| orderStatusProgress.js | app/frontend/lib/orderStatusProgress.js | Маппинг Order.status → шаги progress/ETA | activeOrdersAccordion, OrderStatus | B1.1, b2.1 | — |
| orderStatusCtaMachine.js | app/frontend/lib/orderStatusCtaMachine.js | CTA-машина по status/OS/can_cancel/push/subscription | OrderActionButtons, OrderStatus | #35, #77 | — |
| orderStatusNotifyActions.js | app/frontend/lib/orderStatusNotifyActions.js | Wallet download, push subscribe, open receipt toggle; denied → settings | ActiveOrdersAccordion, OrderStatus | #92, #81, #84 | `openNotificationSettings` + fallback после Android intent (#92); `openOrderReceipt` / `toggleExpandedOrder` сигнатуры не менять (#84) |
| supportChatAdapter | app/frontend/lib/supportChatAdapter.js | Открытие чата поддержки (Telegram URL); same-tab fallback если `window.open` blocked | → OrderStatus, ActiveOrdersAccordion, application.js | #94, #81, #41 | Default `SUPPORT_TELEGRAM_URL`; `assignLocation` fallback — #94; не подставлять произвольный chatUrl из FCM |
| swNotificationActions | app/frontend/lib/swNotificationActions.js | FCM SW actions: tag/options, deep link, cancel/chat/tips; `coffeeos_navigate` / hash boot | → firebase_sw/show.js.erb; application.js; OrderStatus | #94, #38 | `handleCoffeeosNavigateMessage` / `handleCoffeeosHashBoot` — chat → openSupportChat (#94); зеркало логики в classic SW |
| firebasePush.js | app/frontend/lib/firebasePush.js | FCM/WebPush: requestPermission, token, POST /shop/api/push/register | → orderStatusNotifyActions (`subscribeOrderPush` / `registerShopPush`) | #92, #81 | Регистрацию токена / VAPID / endpoint register не менять ради recovery UI (#92) |
| application.js (shop entry) | app/frontend/entrypoints/application.js | Boot shop PWA: mount App, online flush, SW message + hash navigate | → swNotificationActions, supportChatAdapter, shopPwa | #94 | Listener `coffeeos_navigate` + `handleCoffeeosHashBoot` на cold-start (#94); не раздувать boot сторонней логикой |
| firebase_sw (FCM) | app/views/shop/firebase_sw/show.js.erb | Classic FCM SW: onBackgroundMessage showNotification; notificationclick actions | → swNotificationActions (зеркало); FcmClient data payload | #94, #38 | Title/body из `data.*` при data-only FCM (#94); `openWindow` + postMessage `coffeeos_navigate`; не возвращать top-level `notification` в FcmClient |
| FcmClient | app/services/shop/fcm_client.rb | FCM HTTP v1 deliver; data-only message (title/body в data) | → OrderStatusPushNotifier, ReadyPushJob, SendPushNotificationJob | #94 | Data-only web shape (#94) — без top-level `notification`, иначе Android мимо SW; stringify arrays/hashes |
| frequentRepeatStore.js | app/frontend/lib/frequentRepeatStore.js | Store hasActiveOrder; gate Repeat в CartSheet | CartSheet, OrderStatusSheet, RepeatSection | — | — |
| widgetRepeatPayFlow | app/frontend/lib/widgetRepeatPayFlow.js | One-click widget Init → poll → confirmed/error UI | → RepeatSection; clearCartAfterSuccessfulPay (#87) | #87 | На `confirmed` — clear leftover cart (#87); payment Init/Charge контракт не менять |
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
1. ActiveOrdersPresenter уже отдаёт items/modifiers/totals в JSON — backend, вероятно, готов.

**Известный технический долг (вне этой зоны, зафиксировано отдельно):**  
`todo-email-collection.md` и `todo-personal-cabinet.md` существуют параллельно основному `todo.md`, нарушая правило «один живой файл» (`coffeeos-context-hygiene.mdc`). Не трогать без отдельной задачи на очистку.

---

## Как обновлять (БЛОК 4 после Review)

Только когда тесты зелёные **и** владелец принял результат; задача **главная** для этой зоны (новый/удалённый/переименованный компонент или смена связей/стейта).

Канон БЛОК 4 (мультифайл): `docs/operations/dev/TASK_PATCH.md` § шаг 6 · `/patch`.

Кратко: **один файл = одна строка**; точечно PR + «Не трогать»; «Назначение» = что делает файл (не имя задачи); закрытые дыры/аудиты — убрать; коммит `docs: update COMPONENT_MAP — […]`.

Не главная задача / нет смены строки карты → карту не трогать.
