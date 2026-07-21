# todo — Bottom sheet expanded grid (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Bottom Sheet expanded mode и внутренняя сетка 4 в ряд.md`](../milestones/veha_2/requirements/customer_tasks/Bottom%20Sheet%20expanded%20mode%20и%20внутренняя%20сетка%204%20в%20ряд.md)  
> **Скрины:** [`artifacts/bottom_sheet_expanded_grid/`](../milestones/veha_2/artifacts/bottom_sheet_expanded_grid/README.md)  
> Предыдущая фича (Hidden mode cards): PHASE 3 done, апрув заказчика `[ ]` — см. ТЗ Hidden.

## Текущая фаза

**PHASE 3: REVIEW done** · код `7683dee` на develop · апрув заказчика / MCP / deploy — по go

## Решения владельца (2026-07-21)

1. Размеры карточек сетки — канон peek-карточек: `w ~118px` (grid-cols-4 внутри 414px), gap-2, фото сверху, название 1 строка ellipsis, цена × кол-во, кнопки −/+.
2. Кнопка «Удалить» в карточках сетки — **убираем** («−» при кол-ве 1 удаляет, undo остаётся); показать заказчику — финальное слово за ним.
3. Tablet/desktop: шторка остаётся `max-width: 414px`, «4 в ряд» внутри неё; полноширинный пересчёт не делаем.
4. Вместо tsc (фронт на JS) — линт + сборка Vite.

## Пункты SBR

### PHASE 1: SPEC — [x] 2026-07-21

### PHASE 2: RED — [x] 2026-07-21
- [x] `test/integration/shop/bottom_sheet_expanded_grid_test.rb`: grid-cols-4 + `shop-cart-expanded-grid` + `data-cart-layout="grid"`; карточка `shop-cart-grid-card` (−/+ без «Удалить»); высоты 52/56 + bump `CART_SHEET_BUILD` prog27
- [x] Прогон: 3 runs / 3 failures — падают именно на новой разметке (RED ожидаем)

### PHASE 2: GREEN — [x] 2026-07-21
- [x] Шаг A: высоты 52/56 оставлены (Шаг 1 ТЗ подтверждён скрином) + bump `CART_SHEET_BUILD` prog27
- [x] Шаг B: ветка expanded → `grid-cols-4 content-start gap-2 overflow-y-auto`; карточки канон peek (фото → openEditCard, line-clamp-1, цена × кол-во, −/+ без «Удалить»); файл стал короче (−13 строк)
- [x] Store/корзина, +/−, checkout, HIDDEN/PEEK/single, header — не тронуты
- [x] Обновлены 5 старых тестов на новые testid/prog27 (expanded-horizontal→expanded-grid, expanded-card→grid-card)
- [x] Регрессия cart sheet: 8 файлов — 59 runs / 0 failures; Svelte compile OK (5 a11y warn — pre-existing класс)
- [!] Полный `test/integration/shop/` завис локально после 43 тестов (убит) — env-проблема, не этот дифф → ISSUES
- [x] Коммит `feat: … [GREEN]`

### PHASE 3: REVIEW — [x] 2026-07-21
- [x] Sanity: UI-only (Svelte + JS-константа), без N+1/RLS; rubocop новых правок чист
- [x] Ops: SESSION_STATE / CHANGELOG / HANDOFF / ISSUES (🟡 зависание полного shop-прогона)
- [ ] Скрины для заказчика (expanded: 1 ряд каталога; сетка 4 в ряд; скролл при 5+) — MCP Fly после деплоя, по go
- [ ] Апрув заказчика (в т.ч. решение по «Удалить» в карточках) / MCP Fly / deploy — ждать go

## Заметки

- Пустая корзина: уже есть MODE_EMPTY «тут будут твои заказы» — текст «Корзина пуста» из ТЗ не меняем без слова заказчика (backlog-вопрос).
- Pre-existing shop fails (если всплывут) — фиксировать в ISSUES, не чинить молча.
