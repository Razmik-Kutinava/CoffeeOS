# todo — Hidden mode cards (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Исправление режима отображения Hidden для карточек товаров.md`](../milestones/veha_2/requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)  
> **Скрины:** [`artifacts/product_card_hidden_mode/screenshots/`](../milestones/veha_2/artifacts/product_card_hidden_mode/screenshots/README.md)

## Текущая фаза

**PHASE 1: SPEC** — импортировано · Gate 1 · ждать **go** → PHASE 2 RED

## Анализ (SPEC)

| Тема | Вердикт |
|------|---------|
| RLS / tenant | UI-only (Svelte). Данные товаров не меняем. `Current.tenant_id` / API не трогаем |
| Структура данных | Не менять (ограничение ТЗ) |
| Файлы (оценка) | `CategorySection.svelte` (~41 стр.) — норма; возможно CSS/маркеры testid. `CartSheet` peek/expanded — **не ломать** |
| Зона регрессии | `bin/rails test test/integration/shop/` (+ существующие product_card / b113 cart sheet) |
| Эталон | `01_target_hidden_crop_as_should_be.png` |
| Баг as-is | `02_as_is_broken_hidden_sliver.png` — тонкая полоска / пустой crop в hidden |

## Пункты SBR

### PHASE 1: SPEC
- [x] Импорт ТЗ заказчика в todo
- [x] Анализ RLS / лимитов файлов
- [x] SESSION_STATE — старт SBR Hidden
- [ ] Gate 1 — **go** → RED

### PHASE 2: BUILD → RED
- [ ] S1 — тест: hidden + image → crop (object-fit cover / фиксированная высота превью)
- [ ] S2 — тест: hidden без image → placeholder «Нет фото»
- [ ] S3 — тест: переход hidden ↔ peek/expanded не ломает маркеры peek/expanded
- [ ] S4 — тест: гориз. ряд — одинаковая высота карточек + имя + цена
- [ ] Edge — 404 → «Нет фото»; длинное имя → ellipsis/line-clamp
- [ ] Коммит `test: … [RED]` · стоп Gate 2

### PHASE 2: BUILD → GREEN
- [ ] Реализация crop/высоты в hidden (не трогать peek/expanded UX)
- [ ] Зелёные тесты задачи
- [ ] Регрессия зоны shop
- [ ] Коммит `feat: … [GREEN]`

### PHASE 3: REVIEW
- [ ] Sanity + ops (CHANGELOG / HANDOFF / SESSION_STATE)
- [ ] Апрув заказчика / MCP при необходимости

## Заметки

- Команда продолжения: **go**
- Намеренный RED `[TDD]` ≠ ISSUES
- Skeleton / orientation / empty category — в edge; если вылезает за шаг — backlog в ТЗ
