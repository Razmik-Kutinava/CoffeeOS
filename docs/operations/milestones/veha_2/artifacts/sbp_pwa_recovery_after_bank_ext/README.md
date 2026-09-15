# #86 — Восстановление PWA после оплаты СБП (EXT)

**ТЗ:** [`../../requirements/customer_tasks/TASK-86-Восстановление PWA после оплаты СБП-EXT.md`](../../requirements/customer_tasks/TASK-86-Восстановление%20PWA%20после%20оплаты%20СБП-EXT.md)

**Google Doc:** https://docs.google.com/document/d/1i12UGabEH3UJQrR9y7tQS9ONZMvOxG_ARCg3bKcdDoU/edit?usp=drivesdk

**Связь:** reopen CODE:BLACK · split recovery из #79 — [`../sbp_return_status_screen_autopay_labels/`](../sbp_return_status_screen_autopay_labels/) · [`../codeblack_t_kassa_sbp_tokenization/`](../codeblack_t_kassa_sbp_tokenization/)

## Содержимое

| Папка / файл | Назначение |
|---|---|
| `screenshots/` | Скрины заказчика / приёмки (пока пусто) |
| `device/android/` | Device E2E Android (lifecycle + result) |
| `device/ios/` | Device E2E iOS (lifecycle + result) |
| `mcp/fly_vNNN_…/` | MCP Point A после реализации |

## Интейк 2026-09-15

Правки заказчика (п.7): экран после возврата из банк-приложения — «БОЛЬШАЯ ПРОБЛЕМА» на Android; бесшовное восстановление «не вышло»; iOS нужен тест. SMS-ссылка на гл. экран — **OUT** → каскад отдельно. Надписи автоплатежа / 11·8 СБП — **OUT** → #79.
