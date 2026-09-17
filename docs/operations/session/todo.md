# todo — #94 TASK_92: Production background FCM + status sync

| Поле | Значение |
|------|----------|
| **ID** | CBR **#94** (Google/customer: TASK_92) |
| **Тип** | SBR · reopen #38/#81: фоновые FCM + чат CTA |
| **Статус** | **regress PASS** 2026-09-17 · ждёт `/review` |
| **RED** | `20c05ba6` |
| **GREEN** | `f274c11c` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` · unlazy `GATES.md` |
| **ТЗ** | [`TASK-92-Production-background-FCM-и-синхронизация-статусов-заказа.md`](../milestones/veha_2/requirements/customer_tasks/TASK-92-Production-background-FCM-и-синхронизация-статусов-заказа.md) |
| **Google** | https://docs.google.com/document/d/1gcML9WkV4n2s6KNsDN0sobY3ITm4Dge9kOjStzf917g/edit?usp=sharing |
| **Артефакты** | [`production_background_fcm_status_sync/`](../milestones/veha_2/artifacts/production_background_fcm_status_sync/) |
| **GATES** | [`GATES.md`](GATES.md) — G1–G4 baseline met · G5 Fly pending |
| **OUT** | Barista::OrdersController / OrderStatusUpdateService · полный Wallet redesign · CBR #92 WebPush recovery UI · gem’ы оплаты · RSpec/Vitest стек из ТЗ |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `20c05ba6`
- [x] PHASE 2 GREEN
- [ ] PHASE 3 `/review`

## Next

`/review` — bugbot + security · Entire · push/CI · G5 Fly после deploy.

## DoD

1. При валидном FCM token и смене статуса (`accepted`/`preparing`/`ready`) Android **фоновый** пуш управляется SW: **tag** дедуп, **actions**, прогресс в тексте — не «голый» system notification без actions.
2. Кнопка **«Чат с поддержкой»** на карточке заказа (`OrderStatus`) **открывает** support (не мёртвый `orderDeepLink` без handler).
3. Клик Chat из FCM shade (если SW postMessage / deep link) доводит до support или явного navigate handler — не silent no-op.
4. `Barista::OrdersController` / `Barista::OrderStatusUpdateService` — **без diff**.
5. Не ломать существующий accordion path `openSupportChat` и GATES G1–G4 зону.

## Факт кода (SPEC)

| Вопрос | Ответ |
|--------|--------|
| Backend payload tag/actions/progress | Уже в `OrderStatusPushPayload` / `OrderStatusPushNotifier` |
| Почему фон «не реализован» | `FcmClient` шлёт `notification`+`data` → Android часто **не** зовёт SW `onBackgroundMessage` → нет custom tag/actions |
| Чат CTA на OrderStatus | `onCtaClick` → `location.assign(orderDeepLink)` — **нет** `openSupportChat` / parser `?action=` |
| Чат в accordion | Уже `openSupportChat` |
| SW → app | `postMessage({ type: "coffeeos_navigate" })` — **нет** listener в `application.js` |

## Файлы (ожидаемо)

- `app/services/shop/fcm_client.rb` — web/PWA message shape так, чтобы SW владел showNotification (tag/actions)
- `app/frontend/routes/OrderStatus.svelte` — chat CTA → `openSupportChat` (не мёртвый deep link)
- `app/frontend/lib/supportChatAdapter.js` — opener + fallback если `window.open` блокируется
- `app/frontend/lib/swNotificationActions.js` — контракт actions / deep link для SW
- `app/frontend/entrypoints/application.js` — listener `coffeeos_navigate` от FCM SW
- `app/views/shop/firebase_sw/show.js.erb` — выравнивание SW с payload/actions (blast)

### Соседи (blast-radius)

- `app/jobs/shop/ready_push_job.rb` — тот же FcmClient path на `ready`
- `app/frontend/components/ActiveOrdersAccordion.svelte` — эталон chat → `openSupportChat`
- `app/frontend/lib/orderStatusCtaMachine.js` — только labels/matrix; не трогать без нужды

## Не ломать

- Оплата / Checkout / SBP return (#79/#86)
- Статусная шторка accordion: Peek / dismiss / receipt (#83/#84)
- WebPush recovery after denied (#92) UI
- Subscribe path `firebasePush.js` / register token (не ломать granted flow)

## Проверка

- `ruby bin/rails test test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb`
- `node --test test/javascript/support_chat_adapter_test.mjs test/javascript/order_status_push_subscribe_test.mjs`

## Тесты (ожидаемо RED)

- `test/services/shop/fcm_client_test.rb` — assert web-safe message shape (data-driven / SW-owned)
- `test/javascript/support_chat_adapter_test.mjs` — fallback / OrderStatus wiring contract
- `test/javascript/order_status_push_subscribe_test.mjs` — OrderStatus chat → `openSupportChat` (не только accordion)
