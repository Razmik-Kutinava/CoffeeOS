# todo — Hidden mode cards (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Исправление режима отображения Hidden для карточек товаров.md`](../milestones/veha_2/requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)  
> **Скрины:** [`artifacts/product_card_hidden_mode/screenshots/`](../milestones/veha_2/artifacts/product_card_hidden_mode/screenshots/README.md)

## Текущая фаза

**PHASE 2: BUILD → GREEN done** · ждать **go** → PHASE 3 REVIEW

## Анализ (SPEC)

| Тема | Вердикт |
|------|---------|
| RLS / tenant | UI-only (Svelte). Данные товаров не меняем. `Current.tenant_id` / API не трогаем |
| Структура данных | Не менять (ограничение ТЗ) |
| Файлы (оценка) | `CategorySection.svelte` — crop/testid/mode/onerror |
| Зона регрессии | `bin/rails test test/integration/shop/` |
| Эталон | `01_target_hidden_crop_as_should_be.png` |
| Баг as-is | `02_as_is_broken_hidden_sliver.png` |

## Пункты SBR

### PHASE 1: SPEC
- [x] Импорт ТЗ заказчика в todo
- [x] Анализ RLS / лимитов файлов
- [x] SESSION_STATE — старт SBR Hidden
- [x] Gate 1 — **go** → RED

### PHASE 2: BUILD → RED
- [x] S1–S4 + edge тесты
- [x] Коммит `test: … [RED]` · Gate 2

### PHASE 2: BUILD → GREEN
- [x] Реализация crop/высоты в hidden (`CategorySection.svelte`)
- [x] Зелёные тесты задачи (`catalog_hidden_card_test` 7/0)
- [x] Регрессия зоны shop — PARTIAL: 311 runs / 8 fail **pre-existing** (не CategorySection)
- [x] Коммит `feat: … [GREEN]` `71d6eb6`

### PHASE 3: REVIEW
- [ ] Sanity + ops (CHANGELOG / HANDOFF / SESSION_STATE)
- [ ] Апрув заказчика / MCP при необходимости

## Заметки

- Команда продолжения: **go** → PHASE 3 REVIEW
- Тест задачи: `catalog_hidden_card_test` — PASS
- CartSheet peek/expanded не меняли
- Pre-existing shop fails: CBR SBP/canPay, B113 `MODE_PEEK &&`, CART_SHEET_BUILD prog23, order_status CBR
