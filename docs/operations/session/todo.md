# todo — Bottom sheet expanded grid (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Bottom Sheet expanded mode и внутренняя сетка 4 в ряд.md`](../milestones/veha_2/requirements/customer_tasks/Bottom%20Sheet%20expanded%20mode%20и%20внутренняя%20сетка%204%20в%20ряд.md)  
> **Скрины:** [`artifacts/bottom_sheet_expanded_grid/`](../milestones/veha_2/artifacts/bottom_sheet_expanded_grid/README.md)  
> Предыдущая фича (Hidden mode cards): PHASE 3 done, апрув заказчика `[ ]` — см. ТЗ Hidden.

## Текущая фаза

**PHASE 1: SPEC done** · жду **go** на PHASE 2: RED

## Решения владельца (2026-07-21)

1. Размеры карточек сетки — канон peek-карточек: `w ~118px` (grid-cols-4 внутри 414px), gap-2, фото сверху, название 1 строка ellipsis, цена × кол-во, кнопки −/+.
2. Кнопка «Удалить» в карточках сетки — **убираем** («−» при кол-ве 1 удаляет, undo остаётся); показать заказчику — финальное слово за ним.
3. Tablet/desktop: шторка остаётся `max-width: 414px`, «4 в ряд» внутри неё; полноширинный пересчёт не делаем.
4. Вместо tsc (фронт на JS) — линт + сборка Vite.

## Пункты SBR

### PHASE 1: SPEC — [x] 2026-07-21

### PHASE 2: RED — [ ]
- [ ] Тест (Rails integration, стиль b113): expanded-ветка CartSheet — grid 4 в ряд (`grid-cols-4`), вертикальный `overflow-y-auto`, testid `shop-cart-expanded-grid`, line-clamp названия
- [ ] Тест: `cartSheetThresholds.js` — высота expanded / маркер `CART_SHEET_BUILD` обновлён
- [ ] Прогон: падают именно на новой разметке → коммит `test: … [RED]` → стоп до go

### PHASE 2: GREEN — [ ]
- [ ] Шаг A: `SHEET_VH.expandedMulti` — верх шторки у начала 2-го ряда каталога (по скрину близко; верифицировать) + bump `CART_SHEET_BUILD`
- [ ] Шаг B: ветка `MODE_EXPANDED && count >= 2` в `CartSheet.svelte` → grid-cols-4 + внутренний overflow-y-auto; карточки по канону peek; 1–3 товара занимают 1/4 ширины каждая; placeholder «нет» и line-clamp сохранить
- [ ] Не трогать: store/корзину, +/−, checkout-кнопку, HIDDEN/PEEK/single ветки, header
- [ ] CartSheet.svelte 549 строк (>200) — вынести grid-карточку в snippet, файл не раздувать; при росте — план сплита отдельно
- [ ] Регрессия зоны: `bin/rails test test/integration/shop/` + линт/сборка Vite
- [ ] Коммит `feat: … [GREEN]`

### PHASE 3: REVIEW — [ ]
- [ ] Sanity: UI-only, без N+1/RLS
- [ ] Ops: SESSION_STATE / CHANGELOG / HANDOFF
- [ ] Скрины для заказчика (expanded: 1 ряд каталога виден; сетка 4 в ряд; скролл при 5+) → артефакты
- [ ] Апрув заказчика (в т.ч. решение по «Удалить» в карточках) / MCP Fly / deploy — ждать go

## Заметки

- Пустая корзина: уже есть MODE_EMPTY «тут будут твои заказы» — текст «Корзина пуста» из ТЗ не меняем без слова заказчика (backlog-вопрос).
- Pre-existing shop fails (если всплывут) — фиксировать в ISSUES, не чинить молча.
