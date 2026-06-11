# Задача: Интерактивное табло баристы (CoffeeOS)

**ID:** B2.1 · **Источник:** заказчик, чат 2026-06  
**Приоритет:** блок 2 (сейчас)  
**Связано:** B1.1 (WS + push гостю) · B1.7 (витрина, оплата картой) · [B2.2](B2_2_barista_menu_create_merge.md) (меню + создать)

| Сводка | Статус |
|--------|--------|
| **MVP B2.1 целиком** | `[ ]` в работе — этапы 0–4 закрыты, этап 5 впереди |
| **Реализация (мы)** | `[~]` ~80% плана этапов |
| **Приёмка заказчика** | `[ ]` дата ______ · комментарий ______ |
| **Последний коммит** | этап 3–4 (2026-06-11, см. git log) |

---

## Прогресс по этапам

```
[✓] 0 — маппинг + baseline
[✓] 1 — карточка (layout, цвета, кнопка, модификаторы)     2026-06-10  a75ed5f
[✓] 2 — FIFO, без drag-hint, resync колонок                 2026-06-11  885b5e5
[✓] 3 — гость: тексты push/WS, retry cable, тесты           2026-06-11
[✓] 4 — отмена: overlay на карточке, resync колонки         2026-06-11
[ ] 5 — fly smoke, acceptance json, скрины Fly, подпись      ← СЛЕДУЮЩИЙ
--- не MVP B2.1 (фаза 2/3) ---
    брак, переделка, возврат, звук, кухня, PWA, defect_reasons
```

---

## Мастер-чеклист

### Этап 0 — маппинг `[x]` 2026-06-10

- [x] Маппинг статусов ↔ колонки ↔ цвета
- [x] Baseline-скрин `barista_board_before.png`
- [x] Артефакт `b21_stage0_mapping_2026-06-10.json`

### Этап 1 — карточка `[x]` 2026-06-10 · коммит `a75ed5f`

- [x] Квадратная карточка фиксированного размера (`min-height 280px`)
- [x] Цвет по статусу: `accepted` синий · `preparing` оранжевый · `ready` зелёный
- [x] Кнопка ≥80px на всю ширину: ГОТОВИТСЯ / ГОТОВ / Выдать
- [x] Модификаторы: `+ КАПС` жирным · `БЕЗ …` зачёркнуто (helper `barista_modifier_tags`)
- [x] Убраны мелкие кнопки «Принять →» / «✕» / детали по клику
- [x] N+1 по `order_status_logs` — preload в dashboard + broadcaster
- [x] Артефакт `b21_stage1_card_ui_2026-06-10.json`
- [x] Скрины: `stage1_card_accepted.png`, `stage1_card_preparing.png`, `stage1_card_ready.png`, `stage1_modifiers.png`

**Сознательно не в этапе 1:** цена и промокод на карточке убраны (не в MVP карточки).

### Этап 2 — FIFO `[x]` 2026-06-11 · коммит `885b5e5`

- [x] `created_at ASC` в колонке — `Barista::BoardOrdersQuery.for_column`
- [x] Убрана подсказка «Перетащите карточку…» → «нажмите кнопку на карточке»
- [x] Нет drag-and-drop JS в barista
- [x] После смены статуса — resync всей колонки (turbo + `OrderBoardBroadcaster`), FIFO в целевой колонке
- [x] Turbo-шаблон перенесён в `barista/orders/update_status.turbo_stream.erb`
- [x] Тесты: `board_orders_query_test`, FIFO #16–17 в `barista_tablet_regression_test` — PASS
- [x] Артефакт `b21_stage2_fifo_2026-06-11.json`
- [ ] Скрины: `stage2_fifo_accepted.png`, `stage2_after_status_move.png` *(localhost, файлов пока нет)*

### Этап 3 — гость (WS + push) `[x]` 2026-06-11

Цепочка: `OrderStatusUpdateService` → `GuestOrderBroadcaster` → `shopOrderCable.js` + `OrderStatus.svelte` + `OrderStatusPushNotifier`.

- [x] Текст push `accepted` → `preparing`: **«Ваш заказ начали готовить»** — `BARISTA_TRANSITION_BODIES`
- [x] Текст push `preparing` → `ready`: **«Заказ готов, забирайте!»**
- [x] Экран гостя: подзаголовки `status-subtitle` в `orderStatusProgress.js` + `OrderStatus.svelte`
- [x] WS бариста → гость — тест `guest_order_channel_test` + `b21_guest_notify_test`
- [x] Retry WS при сбое (3×, интервал 5 с) — `shopOrderCable.js`
- [x] Артефакт `b21_stage3_guest_notify_2026-06-11.json`
- [ ] Push на реальном устройстве (FCM) — `stage3_push_optional.png`
- [ ] Скрины localhost: `stage3_guest_preparing.png`, `stage3_guest_ready.png`
- [ ] Браузерный e2e витрина→бариста→гость — формально на этапе 5

**Файлы:** `order_status_push_notifier.rb`, `orderStatusProgress.js`, `OrderStatus.svelte`, `shopOrderCable.js`

### Этап 4 — отмена (упрощённо) `[x]` 2026-06-11

- [x] Overlay на карточке: тёмно-серый, «СТОП! ЗАКАЗ ОТМЕНЁН», «ПОДТВЕРДИТЬ ОТМЕНУ»
- [x] UI отмены: кнопка ✕ → overlay (`order_card_cancel_controller.js`)
- [x] Resync колонки при отмене — `cancel.turbo_stream.erb` + `OrderBoardBroadcaster`
- [x] Без звука и списания (MVP) — `ingredients_used` не передаётся
- [x] Артефакт `b21_stage4_cancel_2026-06-11.json`
- [ ] Скрины: `stage4_cancel_overlay.png`, `stage4_cancel_confirmed.png` *(localhost)*

### Этап 5 — финальная приёмка `[ ]`

- [ ] Полный прогон тестов B2.1
- [ ] Создать и прогнать `bin/b21_barista_board_fly_smoke.rb`
- [ ] MCP Fly на `coffeeos.fly.dev`
- [ ] Скрины Fly: `barista_board_after.png`, `stage5_e2e_vitrina_to_board.png`
- [ ] Артефакт `b21_acceptance_YYYY-MM-DD.json` — все критерии MVP PASS/FAIL
- [ ] Артефакт `b21_mcp_fly_YYYY-MM-DD.json`
- [ ] Приёмка заказчика — подпись

**Скрины этапов 1–4:** localhost. **Скрины этапа 5:** Fly после deploy.

### Фаза 2/3 — вне MVP B2.1

- [ ] Брак / переделка / возврат на карточке
- [ ] `defect_reasons`, справочник причин
- [ ] Звук при отмене
- [ ] Переделка → возврат в начало очереди «Готовится»
- [ ] Табло кухни / `prep_kitchen`
- [ ] PWA

---

## Критерии приёмки MVP

| # | Критерий | Цель | Код | Формально |
|---|----------|------|-----|-----------|
| 1 | Кнопка статуса ≥ 80 px, на всю ширину | да | `[x]` | `[ ]` |
| 2 | Цвет карточки по статусу | да | `[x]` | `[ ]` |
| 3 | Модификаторы: + выделены, БЕЗ зачёркнуты | ≥ 98% | `[x]` UI | `[ ]` e2e с витрины* |
| 4 | FIFO в колонке по `created_at` | 100% | `[x]` | `[ ]` |
| 5 | Нет drag-and-drop | да | `[x]` | `[ ]` |
| 6 | Смена статуса → табло ≤ 1 с | ≤ 500 мс | `[~]` | `[ ]` не замеряли |
| 7 | Смена статуса → WS гостю ≤ 5 с | B1.1 | `[x]` тесты | `[ ]` браузер e2e |
| 8 | Смена статуса → push (если FCM) | B1.1 | `[x]` тексты | `[ ]` устройство |
| 9 | Заказ с витрины на табло | да | `[~]` | `[ ]` e2e этап 5 |

\*Колонка «Код» — реализовано в коде; «Формально» — закрыто артефактом приёмки этапа 5.

---

## Хвосты и бэклог (тащим между этапами)

| Хвост | Статус | Когда закрывать |
|-------|--------|-----------------|
| `removed_modifiers` — ключ в JSONB готов, helper читает | витрина пишет только `selected_modifiers` | checkout витрины (не B2.1) |
| Цена / промокод на карточке | убраны намеренно | — |
| Скрины stage2 | в артефакте указаны, файлов нет | localhost до/параллельно этапу 3 |
| Отмена: backend есть, UI отключён | overlay в этапе 4 | этап 4 |
| `bin/b21_barista_board_fly_smoke.rb` | не создан | этап 5 |
| Критерии MVP / приёмка заказчика | все `[ ]` | этап 5 |

---

## Осознанные отступления от PDF заказчика

| Тема в PDF | Решение CoffeeOS |
|------------|------------------|
| Цена / промокод на карточке | не в MVP карточки |
| Клик по карточке → детали заказа | убран |
| Брак / переделка / возврат | фаза 2/3 |
| Звук при отмене | фаза 2/3 |
| PWA | не MVP |
| Кухня / prep_kitchen | после витрина↔бариста |
| Наличные в «Создать заказ» бариста | **B2.2**, не B2.1 |
| «Принят» серый на табло | на табло только `accepted`/`preparing`/`ready` после оплаты |

---

## Соседние задачи (не B2.1)

| ID | Задача | Связь с табло |
|----|--------|---------------|
| **B1.1** | WS + push гостю | этап 3 = тексты + e2e поверх готовой инфры |
| **B1.7** | Витрина, оплата картой | цепочка витрина → табло |
| **B2.2** | Меню + «Создать» бариста, убрать наличные | отдельное ТЗ |

---

## CoffeeOS — scope

| Тема | Решение |
|------|---------|
| **Канал** | Web `/barista` (Rails + Hotwire/Turbo) |
| **Цепочка** | Витрина (карта) → табло бариста → экран статуса гостя (B1.1) |
| **Колонки** | `accepted` · `preparing` · `ready` |
| **Выдача** | кнопка «Выдать» на `ready` → `issued`, без нового экрана |
| **Уведомления** | `GuestOrderBroadcaster` + `OrderStatusPushNotifier` (web, не PWA) |

### Код (ключевые файлы)

| Компонент | Файл |
|-----------|------|
| Табло | `app/views/barista/dashboard/index.html.erb` |
| Карточка | `app/views/barista/dashboard/_order_card.html.erb` |
| Колонка FIFO | `app/views/barista/dashboard/_orders_column.html.erb` |
| FIFO-запрос | `app/services/barista/board_orders_query.rb` |
| Смена статуса | `app/controllers/barista/orders_controller.rb#update_status` |
| Сервис статуса | `app/services/barista/order_status_update_service.rb` |
| Broadcast табло | `app/services/barista/order_board_broadcaster.rb` |
| Turbo ответ | `app/views/barista/orders/update_status.turbo_stream.erb` |
| Broadcast гостю | `app/services/shop/guest_order_broadcaster.rb` |
| Push | `app/services/shop/order_status_push_notifier.rb` |
| Экран гостя | `app/frontend/routes/OrderStatus.svelte`, `lib/orderStatusProgress.js` |
| Fly smoke | `bin/b21_barista_board_fly_smoke.rb` *(создать на этапе 5)* |

### Артефакты

| Файл | Этап | Статус |
|------|------|--------|
| `b21_stage0_mapping_2026-06-10.json` | 0 | `[x]` |
| `b21_stage1_card_ui_2026-06-10.json` | 1 | `[x]` |
| `b21_stage2_fifo_2026-06-11.json` | 2 | `[x]` |
| `b21_stage3_guest_notify_2026-06-11.json` | 3 | `[x]` |
| `b21_stage4_cancel_2026-06-11.json` | 4 | `[x]` |
| `b21_acceptance_*.json` | 5 | `[ ]` |
| `b21_mcp_fly_*.json` | 5 | `[ ]` |

**Скрины:** [`screenshots/b21_barista_board_2026-06-10/`](../../artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10/)

| Скрин | Этап | Статус |
|-------|------|--------|
| `barista_board_before.png` | 0 | `[x]` |
| `stage1_card_*.png`, `stage1_modifiers.png` | 1 | `[x]` |
| `stage2_fifo_accepted.png`, `stage2_after_status_move.png` | 2 | `[ ]` |
| `stage3_guest_*.png` | 3 | `[ ]` localhost |
| `stage4_cancel_*.png` | 4 | `[ ]` localhost |
| `barista_board_after.png`, `stage5_e2e_vitrina_to_board.png` | 5 | `[ ]` |

### Приёмка (итоговая)

| Измеритель | Код готов | Формально закрыто | Заказчик |
|------------|-----------|-------------------|----------|
| Карточка + кнопка + цвет | `[x]` | `[ ]` | `[ ]` |
| FIFO | `[x]` | `[ ]` | `[ ]` |
| Модификаторы | `[x]` UI | `[ ]` | `[ ]` |
| Витрина → табло → гость | `[~]` WS/push код | `[ ]` | `[ ]` |

---

## Маппинг: статусы ↔ колонки

| Колонка UI | `Order.status` | Цвет (MVP) | Кнопка |
|------------|----------------|------------|--------|
| ACCEPTED | `accepted` | синий | ГОТОВИТСЯ → `preparing` |
| PREPARING | `preparing` | оранжевый | ГОТОВ → `ready` |
| READY | `ready` | зелёный | Выдать → `issued` |

На табло: заказы с витрины (`source: mobile`) после оплаты и ручное создание бариста.

---

## MVP vs позже

| Функция | MVP B2.1 | Позже |
|---------|----------|-------|
| Квадратная карточка + цвет + большая кнопка | `[x]` | — |
| Модификаторы + / БЕЗ | `[x]` UI | `removed_modifiers` с витрины |
| FIFO по `created_at` | `[x]` | переделка в начало очереди |
| WS + push гостю | `[x]` этап 3 | PWA |
| Отмена overlay | `[x]` этап 4 | звук, списание |
| Брак / переделка / возврат | — | фаза 2/3 |
| Кухня / prep_kitchen | — | после витрина↔бариста |

---

## Проблема (заказчик)

Табло в формате to-do list: ручное перетаскивание, нет крупной кнопки статуса, нет цветовой обратной связи, модификаторы не видны, нет FIFO, гость не всегда получает понятный статус, нет механик исключений в карточке.

---

## Решение (текст заказчика)

### Блок 1. Интерактивная карточка

- Квадратный блок фиксированного размера: номер, время, состав с модификаторами (**+ ПО КРЕПЧЕ** / **БЕЗ Сахара**).
- Кнопка ≥ 80 px: «Оплачен» → **ГОТОВИТСЯ**; «Готовится» → **ГОТОВ**.
- Цвет: оплачен — синий; готовится — оранжевый; готов — зелёный.

### Блок 2. FIFO

- Очередь по `created_at`, без ручного reorder.
- При смене статуса карточка переходит в следующую колонку.

### Блок 3. Уведомления клиенту

- «Оплачен» → «Готовится»: **«Ваш заказ начали готовить»**.
- «Готовится» → «Готов»: **«Заказ готов, забирайте!»**
- WebSocket; при сбое — повтор до 3 раз, интервал 5 с.

### Блок 4. Исключения

- **Отмена (MVP упрощённо):** overlay «СТОП! ЗАКАЗ ОТМЕНЁН», подтверждение; без звука/списания.
- **Брак / переделка / возврат:** фаза 2/3.

### Ограничения

- Цепочка: Принят → Оплачен → Готовится → Готов.
- Без ручного порядка и произвольного следующего статуса.
- Брак — не бариста (фаза 2/3).

---

## User Story / corner cases

Полный текст — переписка заказчика 2026-06 (конвейер, отмена, брак, двойной клик, офлайн, эскалация отмены 5 мин).
