# #82 — Каскад SMS после ready + шторка статуса на главном

**ТЗ:** [`../../requirements/customer_tasks/Каскад SMS после Заказ готов и шторка статуса на главном.md`](../../requirements/customer_tasks/Каскад%20SMS%20после%20Заказ%20готов%20и%20шторка%20статуса%20на%20главном.md)

**Связь:** канон каскада — [`../order_ready_cascade_ws_push_sms/`](../order_ready_cascade_ws_push_sms/) · статусная шторка — [`../order_status_compact_sheet_push/`](../order_status_compact_sheet_push/) · Svelte 5 UX — [`../svelte5_status_widget_reactivity_ux/`](../svelte5_status_widget_reactivity_ux/)

## Содержимое

| Папка / файл | Назначение |
|---|---|
| `screenshots/` | скрины заказчика / приёмки (пока пусто) |
| `mcp/fly_vNNN_…/` | MCP Point A после фикса |

## Интейк 2026-09-07

Правки п.10: SMS-каскад после «заказ готов» не работает + статусная модель не пропадает с гл. экрана после «готов» на табло. Код не трогали — ждёт `/spec`.
