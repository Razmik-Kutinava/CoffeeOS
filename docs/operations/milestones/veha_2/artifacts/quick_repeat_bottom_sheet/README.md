# Quick Repeat Bottom Sheet — артефакты

**ТЗ:** [`../../requirements/customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](../../requirements/customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)

## Скрины заказчика (канон UI — ревизия 2026-07-31)

| Файл | Подпись заказчика / контекст |
|---|---|
| `screenshots/01_catalog_one_new_item_repeat_section_2026-07-31.png` | «если не выбрал сделать повтор а выбрал одну новую карточку товара» — каталог + секция «повторить» (3 мини-карточки, −1+) |
| `screenshots/02_expanded_single_new_item_not_repeat_2026-07-31.png` | expanded: одна новая позиция (полная строка с модификаторами, «Удалить») + «+цена» + секция «повторить» |
| `screenshots/03_expanded_new_drink_not_from_repeat_2026-07-31.png` | «когда новый напиток не из повтора режим expandad» — ряд мини-карточек сверху + «+цена» + «повторить» снизу |
| `screenshots/04_hidden_single_drink_2026-07-31.png` | «hidden, один напиток» — узкая полоса: 1 превью + кнопка «+цена» |
| `screenshots/05_peek_three_repeat_items_2026-07-31.png` | peek: 3 превью повтора + кнопка «+цена» |
| `screenshots/06_one_click_pay_buttons_2026-07-31.png` | «когда, нажимаешь на в клик оплата» — под каждой картой повтора оранжевая кнопка «полатить в 1 клик» |
| `screenshots/07_customer_feedback_status_sheet_not_full_width_2026-07-31.png` | Fly v415: правило Quick Repeat ещё не сработало; статусная шторка ошибочно сжата слева, справа видна отдельная CartSheet — переделать на всю ширину |

Старые скрины интейка 2026-07-21: `screenshots/_archive_2026-07-21/`.

**Важно:** UI приёмки = скрины 01–06 + corrective feedback 07. При активном заказе секция «повторить» не показывается во всех режимах; OrderStatusSheet — на всю ширину.

## История MCP (не канон UI)

| Прогон | Файл | Итог |
|---|---|---|
| Приёмка стабом 2026-07-21 | [`fly_acceptance_mcp_2026-07-21.json`](fly_acceptance_mcp_2026-07-21.json) | 6/6 PASS · `screenshots/fly_acceptance/` |
| Real-run без стабов 2026-07-21 | [`fly_real_run_mcp_2026-07-21.json`](fly_real_run_mcp_2026-07-21.json) | 8/8 PASS · `screenshots/fly_real_run/` |
| FIX-A…F 2026-07-22 | [`fly_fix_af_mcp_2026-07-22.json`](fly_fix_af_mcp_2026-07-22.json) | 9/9 PASS · `screenshots/fly_fix_af_2026-07-22/` |
| Layout prog28 2026-07-23 | [`fly_layout_prog28_mcp_2026-07-23.json`](fly_layout_prog28_mcp_2026-07-23.json) | PASS · `screenshots/fly_layout_prog28_2026-07-23/` |
