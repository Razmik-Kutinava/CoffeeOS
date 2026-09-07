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
- [x] **GREEN** / **/regress** — JS 21/0
- [x] **REVIEW** — bugbot fix `ffd48c6b` · security OK · Entire `01M1XF20DA5E0PXJ99E9DH2HM6` · push/CI

## REVIEW

- bugbot: medium — settings CTA only when `openSettings` (denied) — **fixed** [`Bugbot`](c308d8da-65a3-4425-9a8f-08857bff1ce2)
- security: no medium+ [`Security Review`](7b9c4fb9-e596-499a-8dcd-ef197465ead5)
- Entire: `01M1XF20DA5E0PXJ99E9DH2HM6` на `ffd48c6b`

## Проверка

- `node --test test/javascript/order_status_push_subscribe_test.mjs test/javascript/support_chat_adapter_test.mjs test/javascript/order_status_notify_actions_test.mjs` → **21/0**
