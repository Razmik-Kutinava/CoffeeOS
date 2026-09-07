# todo — #81 Notifications / Wallet / WebPush gaps

| Поле | Значение |
|------|----------|
| **CBR** | #81 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Косяки%20уведомлений%20Wallet%20WebPush%20фоновые%20и%20кнопка%20чат.md) |
| **Тип** | Fix / hot-path витрина · статусная модель + push/chat CTA |
| **Цель** | Denied-баннер → настройки браузера; «Чат с поддержкой» → Telegram |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/notifications_wallet_webpush_gaps_reopen/`](../milestones/veha_2/artifacts/notifications_wallet_webpush_gaps_reopen/) |

## SBR

- [x] **SPEC** (`80dad7ee`)
- [x] **RED** (`ded3fb8f`)
- [x] **GREEN** (`199344f4` contains code; Entire `01M1XF20DA5E0PXJ99E9DH2HM6`)
- [x] **/regress** — JS 21/0 PASS
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | Denied-баннер = button → `openNotificationSettings` |
| 2 | `subscribeOrderPush` denied → `openSettings: true` |
| 3 | `openSupportChat` / accordion → `SUPPORT_TELEGRAM_URL` |
| 4 | #38 background FCM/Wallet — backlog |

## Файлы (ожидаемо)

- `app/frontend/lib/orderStatusNotifyActions.js`
- `app/frontend/components/ActiveOrdersAccordion.svelte`
- `app/frontend/lib/supportChatAdapter.js`
- `app/frontend/lib/supportConfig.js`
- `test/javascript/order_status_push_subscribe_test.mjs`
- `test/javascript/support_chat_adapter_test.mjs`

## Не ломать

- Wallet iOS · push granted · cancel · #35 peek · max-2 CTA

## Проверка

- `node --test test/javascript/order_status_push_subscribe_test.mjs test/javascript/support_chat_adapter_test.mjs test/javascript/order_status_notify_actions_test.mjs`

## Local GREEN

- JS зона #81: **21/0 PASS** (regress)
- Entire: `01M1XF20DA5E0PXJ99E9DH2HM6` (session `974a53cf-…`)
