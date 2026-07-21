# Quick Repeat Bottom Sheet — артефакты

**ТЗ:** [`../../requirements/customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](../../requirements/customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)

## Скрины заказчика (интейк 2026-07-21)

| Файл | Подпись заказчика / контекст |
|---|---|
| `screenshots/01_peek_repeat_section_catalog_2026-07-21.png` | «если не выбрал сделать повтор а выбрал одну новую карточку товара» — каталог + секция «повторить» (3 мини-карточки, −1+) |
| `screenshots/02_expanded_single_new_item_not_repeat_2026-07-21.png` | expanded: одна новая позиция (полная строка с модификаторами, «Удалить») + кнопка «+цена» + секция «повторить» |
| `screenshots/03_expanded_new_drink_not_from_repeat_2026-07-21.png` | «когда новый напиток не из повтора режим expandad» — сетка 3 карточки с −1+ сверху, «+цена», секция «повторить» снизу |
| `screenshots/04_hidden_single_drink_2026-07-21.png` | «hidden, один напиток» — узкая полоса: 1 превью + кнопка «+цена» |
| `screenshots/05_hidden_three_repeat_items_2026-07-21.png` | hidden: 3 превью повтора + кнопка «+цена» |
| `screenshots/06_one_click_pay_buttons_2026-07-21.png` | «когда, нажимаешь на в клик оплата» — под каждой картой повтора оранжевая кнопка «полатить в 1 клик» |

## Приёмка на Fly (MCP, 2026-07-21)

**Прогон:** [`fly_acceptance_mcp_2026-07-21.json`](fly_acceptance_mcp_2026-07-21.json) — 6/6 PASS (frequent_items засеяны стабом: у стенда нет клиентов с историей mobile-заказов), скрины в `screenshots/fly_acceptance/`. UX-вопросы владельцу: empty/peek высоты vs секция повтора — см. `findings_for_owner` в JSON и DEMO_FEEDBACK.

## Реальный прогон на Fly без стабов (MCP, 2026-07-21)

**Прогон:** [`fly_real_run_mcp_2026-07-21.json`](fly_real_run_mcp_2026-07-21.json) — 8/8 PASS + 1 SKIP (живое списание: точка закрыта, прод T-Bank). На стенде засеян клиент `mcp-quickrepeat@example.com` с историей mobile-заказов; вход штатным email-OTP, данные секции «повторить» — из реального API. Скрины в `screenshots/fly_real_run/`. Там же — **чеклист заказчику** (`customer_checklist`) и новые находки UX-3 / NOTE про guard «Укажите email».
