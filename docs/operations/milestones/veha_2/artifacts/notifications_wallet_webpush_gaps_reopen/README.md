# Artifacts — #81 notifications / Wallet / WebPush gaps reopen

**CBR:** #81  
**ТЗ:** [`customer_tasks/Косяки уведомлений Wallet WebPush фоновые и кнопка чат.md`](../../requirements/customer_tasks/Косяки%20уведомлений%20Wallet%20WebPush%20фоновые%20и%20кнопка%20чат.md)

## Связанные артефакты (исходные задачи)

- [`order_status_os_detect_wallet_webpush/`](../order_status_os_detect_wallet_webpush/) — #37
- [`background_notifications_fcm_apple_wallet/`](../background_notifications_fcm_apple_wallet/) — #38
- [`order_action_buttons_status_panel/`](../order_action_buttons_status_panel/) — #41

## Скрины заказчика

| Файл | Что видно |
|------|-----------|
| [`01_push_denied_browser_settings_2026-09-07.png`](01_push_denied_browser_settings_2026-09-07.png) | Point A `/shop`: статусная модель (accepted/paid), CTA «🔔 Уведомление о готовности», под кнопками оранжевый текст **«Уведомления запрещены в настройках браузера»** без перехода в настройки |

## Этот пакет

MCP/smoke и скрины приёмки по gap-фиксам (denied→settings, chat CTA; фоновые FCM/Wallet — backlog вне slice SPEC).
