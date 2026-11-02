# todo — TASK_121 Subtask 8: Повтор заказов других и закрытых точек (очередь, шаг 16)

| Поле | Значение |
|------|----------|
| **Очередь** | [PUSH_SMS_QUEUE](../milestones/veha_2/requirements/PUSH_SMS_QUEUE.md) · шаг **16** `in_progress` · зависимости 12 / 13 = done |
| **Основание** | [TASK-121-…](../milestones/veha_2/requirements/customer_tasks/TASK-121-Повтор-заказа-из-истории-с-проверкой-цен-в-текущей-точке.md) · секция Subtask 8 · CBR #121 · Google Doc v3 |
| **Статус** | **GREEN** 2026-11-02 · RED `51c50d5e` · GREEN `70da0ca3` · Entire `01M6E6SK26KVPBMSJWMAJXCFQ4` · миграции нет |
| **Субагент** | нет — пути ясны |

## SBR

- [x] intake (шаг 12 + секция Subtask 8 шага 16)
- [x] SPEC — факты = код (ниже) · решения · файлы · Не ломать · Проверка · миграции нет
- [x] RED `51c50d5e` — падающие тесты `[RED]` (сеть / закрытая → 200; вне сети 404)
- [x] GREEN `70da0ca3` — `#repeat_preview` → `CodeBlackCrossPointOrders#find_order!` · local Проверка PASS · Entire `01M6E6SK26KVPBMSJWMAJXCFQ4`
- [ ] `/review`

## Факты = код (сверка на SPEC)

| Документ (Subtask 8) | Код сейчас | Вердикт |
|---|---|---|
| Чтение заказа другой/закрытой точки — механизм TASK_116 | `#show` / `#history` → `CodeBlackCrossPointOrders#find_order!` / `history_orders` (`orders_controller.rb:39-41,131+`); `#repeat_preview` → `scope_visible_orders` (**только текущая точка**, `:27`) | **разрыв** — превью не видит чужую точку сети |
| Позиции пересчитываются по меню **текущей** точки | `HistoryRepeatPreview.new(order:, tenant_id: @shop_tenant.id)` (`:28`) — цены уже от текущей точки | ок, без смены сервиса |
| Сценарий превью/блока тот же (Subtask 1–7) | FE: `runHistoryRepeatPayFlow` → `fetchRepeatPreview` → `compareRepeatPreview` → notice/`/` (`historyRepeatAdapter.js:183-190`) | ок, FE без правок ожидаемо |
| Тест «другая точка → 404» | `orders_repeat_preview_test.rb:119-131` — намеренный 404 шага 12 | **реверс** для сети CODE:BLACK; вне сети 404 остаётся |
| Закрытая точка в сети | `Tenant.code_black_network` без фильтра `status` (`code_black_cross_point_orders.rb:71-76`) — закрытая ∈ сети читается в history/show | превью должно так же |
| Без `customer_id` сессии / чужой клиент | превью: `cid.blank?` → 401; чужой → 404 (`:24-25`, тесты `:83-116`) | не ломать |
| `reconnect_token` не открывает превью | тест `:94-104` | не ломать |

## Решения (узко Subtask 8)

1. В `#repeat_preview` искать заказ через `Shop::CodeBlackCrossPointOrders#find_order!` (как `#show`), не через `scope_visible_orders`.
2. `HistoryRepeatPreview` / FE / Init·Charge / Quick Repeat / `OrderCreator` / `GrowthPromo` — не менять.
3. Вне сети CODE:BLACK — поведение шага 12: чужая точка → 404.
4. В сети: заказ другой или закрытой точки → 200; `unit_total`/`total` по меню **текущей** точки; дальше compare/блок как в Subtask 1–7.
5. Миграции нет. COMPONENT_MAP: строка `OrdersController` — на `/review` (да: граница `repeat_preview` ↔ CodeBlack).

## Файлы (ожидаемо)

- `app/controllers/shop/api/orders_controller.rb` — `#repeat_preview`: find через `CodeBlackCrossPointOrders` (+ `includes(:order_items)` как сейчас)
- `test/integration/shop/api/orders_repeat_preview_test.rb` — реверс/доп. кейсы Subtask 8 (сеть / вне сети / закрытая / цены текущей точки)

### Соседи (blast-radius, без правок ожидаемо)

- `app/services/shop/code_black_cross_point_orders.rb` — только reuse `#find_order!`; контракт history/show не менять
- `app/services/shop/history_repeat_preview.rb` — уже считает по `tenant_id` текущей точки
- `docs/operations/session/COMPONENT_MAP.md` — строка OrdersController на Review

## Scope

- [x] Subtask 8: заказ другой или закрытой точки сети → тот же сценарий превью; цены по меню текущей точки; чтение — TASK_116
- [x] Вне сети: чужая точка → 404 (как шаг 12)
- [x] Backend-тест: заказ другой точки в сети + цены текущей; закрытая точка; вне сети 404

## Не ломать

- Повтор **текущей** точки без отличий цен → как TASK_121 шаг 12 (DELETE cart → add → POST → widget pay)
- `#history` / `#show` CODE:BLACK (TASK_116) — метки точки/`closed`, highlight `?order=`
- Init/Charge (`widgetRepeatPayFlow`), Quick Repeat / общий FSM, `clearCartAfterSuccessfulPay`
- Превью без `customer_id` → 401; чужой клиент → 404; `reconnect_token` не bind’ит сессию

## Проверка

- `bin/rails test test/integration/shop/api/orders_repeat_preview_test.rb test/integration/shop/api/orders_history_code_black_test.rb test/integration/shop/lk_history_repeat_one_click_test.rb`
- `node --test test/javascript/lk_history_repeat_one_click_test.mjs test/javascript/history_repeat_price_check_test.mjs`
