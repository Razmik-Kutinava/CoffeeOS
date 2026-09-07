# todo — #81 Notifications / Wallet / WebPush gaps

| Поле | Значение |
|------|----------|
| **CBR** | #81 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Косяки%20уведомлений%20Wallet%20WebPush%20фоновые%20и%20кнопка%20чат.md) |
| **Тип** | Fix / hot-path витрина · статусная модель + push/chat CTA |
| **Цель** | Denied-баннер → переход в настройки браузера; «Чат с поддержкой» реально открывает Telegram |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/notifications_wallet_webpush_gaps_reopen/`](../milestones/veha_2/artifacts/notifications_wallet_webpush_gaps_reopen/) · скрин `01_push_denied_…png` |

## SBR

- [x] **SPEC**
- [ ] **RED**
- [ ] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | При `denied`: баннер «Уведомления запрещены…» — **кликабельный** CTA (не мёртвый текст); вызов helper открытия настроек уведомлений браузера / site settings (deps injectable для тестов). Best-effort: нельзя открыть — баннер остаётся, без краша. |
| 2 | `subscribeOrderPush` / accordion: на `denied` отдавать флаг/`openSettings` path; UI клик → helper (не только toast). Скрин: текст уже есть — не хватает перехода. |
| 3 | «Чат с поддержкой»: `openSupportChat(orderId)` без URL → всегда pending. Default URL = `SUPPORT_TELEGRAM_URL` (`supportConfig` / `shopAboutConfig` support URL), как в ЛК #70. |
| 4 | **Вне slice:** полный reopen #38 (FCM tag/actions/прогресс, `.pkpass`/APNs, SW actions) — backlog; не тащить в этот SBR. |

## Файлы (ожидаемо)

- `app/frontend/lib/orderStatusNotifyActions.js` — denied path + helper/export для open settings
- `app/frontend/components/ActiveOrdersAccordion.svelte` — клик по denied-баннеру; wire chat URL
- `app/frontend/lib/supportChatAdapter.js` — default Telegram URL если `chatUrl` пуст
- `app/frontend/lib/supportConfig.js` — канон `SUPPORT_TELEGRAM_URL` (#70)
- `test/javascript/order_status_push_subscribe_test.mjs` — RED: denied → settings click/open
- `test/javascript/support_chat_adapter_test.mjs` — RED: open без URL → Telegram

### Blast-radius (+2)

- `app/frontend/routes/OrderStatus.svelte` — свой `pushErr` / denied copy (не ломать, при касании — тот же helper)
- `app/frontend/lib/firebasePush.js` — `reason: "denied"` уже есть; не менять register без нужды

## Не ломать

- iOS Wallet CTA / `downloadWalletPass` + localStorage `wallet_added`
- Push `granted` → «✓ Уведомления включены» + disabled
- Отмена заказа / refund copy в статусной модели
- Peek/CartSheet layout (#35) и матрица max-2 CTA (#41)

## Проверка

- `node --test test/javascript/order_status_push_subscribe_test.mjs test/javascript/support_chat_adapter_test.mjs test/javascript/order_status_notify_actions_test.mjs`
- `node --test test/javascript/order_status_cta_machine_test.mjs` (если есть; иначе skip)
