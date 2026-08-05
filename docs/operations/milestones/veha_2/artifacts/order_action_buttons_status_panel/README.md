# order_action_buttons_status_panel

Динамический контекстный блок действий (Action Buttons) в правой части нижней статусной панели заказа: Отмена → Чат → Чаевые / Push|Wallet по матрице статусов.

**ТЗ:** [`customer_tasks/Динамический блок действий Action Buttons в статусной панели заказа.md`](../../requirements/customer_tasks/Динамический%20блок%20действий%20Action%20Buttons%20в%20статусной%20панели%20заказа.md)

| Папка | Назначение |
|-------|------------|
| `screenshots/` | макет заказчика (плейсхолдеры «кнопка с текстом») / приёмка |
| `mcp/` | evidence MCP DevTools после deploy |

## Скрины интейка (2026-08-05)

| Файл | Что |
|------|-----|
| `screenshots/01_mockup_status_panel_action_placeholders_2026-08-05.png` | Макет: progress bar (Принят/Оплачен/Готовится/Готов) + правый блок с двумя оранжевыми плейсхолдерами |

## MCP Fly v429 (2026-08-05) — **PASS**

| Файл | Что |
|------|-----|
| [`mcp/fly_v429_2026-08-05/MCP_RESULT.md`](mcp/fly_v429_2026-08-05/MCP_RESULT.md) | DOM + deploy evidence |
| `mcp/fly_v429_2026-08-05/01_sticky_panel_orders_cta.png` | Live DOM composite: sticky RIGHT chat+push |
| `mcp/fly_v429_2026-08-05/02_cta_buttons_chat_push.png` | Live CTA strip `#ff6b35` / 44px |
