# CHANGELOG

## Шапка

**Текущий месяц:** `2026-09`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md`

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Архив — по запросу.

---

## Текущий месяц (2026-09)

## 2026-09-02 — feat: УК single-point lists (UkCatalogScope)

- `Platform::UkCatalogScope` — в `DEMO_SINGLE_POINT` только Point A + org в `/admin`
- Без single-point: только `active` sales_point (inactive/prog10 скрыты)
- Скрыты «Новая точка/орг» в single-point; show/edit по id не трогаем
- Тесты: uk_catalog_scope + uk_single_point_dashboard (9 runs PASS в зоне)

## 2026-09-02 — feat: single Point A prod (Fly cleanup + DEMO_SINGLE_POINT)

- `Platform::ProdSinglePointCleanup` — inactive лишних sales_point, без DELETE
- `DEMO_SINGLE_POINT=true` + `SHOP_DEFAULT_TENANT_ID` в `fly.toml`
- `fly:release` → `platform:prod_single_point` после `demo:seed`
- Deploy **v474** · release `[platform:prod_single_point] OK`
- Активны: **demo-point-a** + demo-prep-kitchen (backend)
- Артефакт: `artifacts/single_point_a/cleanup_2026-09-02.json`
- Тесты: platform cleanup + environment_setup + RLS (19 runs PASS)

## 2026-09-02 — ops: ctx-trim токенов (rules + todo + ISSUES)

- Удалены 7 дублей `.cursor/rules/coffeeos-*.mdc` в корне (канон — `project/`)
- Сжат always-бандл: `.cursorrules`, `coffeeos-index.mdc`, `coffeeos-agent-workflow.mdc`
- `todo.md` → stub deploy pending; полный SPEC → `session/archive/todo-shift-close-2026-09.md`
- ISSUES 🔴 — короткая таблица (ID / статус / блокер)
- `coffeeos-performance` globs: убран `test/**`
- **~600 tok/ход** always rules · **~650 tok/старт** todo+ISSUES · **~200 tok/edit** без дублей globs

## 2026-09-01 — chore: uploads gitignore (меньше шума в git status)

- `.gitignore`: убран `!/public/uploads/products/` — картинки локально/Fly эфемерны, в git только README
- Удалены 15 тестовых файлов из `public/uploads/products/` (MCP/локальные загрузки)

## 2026-09-01 — ops: ctx-trim + архив августа

- Коммит `e929d3bd` · ops ref `5b1519a5`
- Команда `/ctx-trim` + правило `coffeeos-context-hygiene.mdc` (ручной + weekly пт–вс)
- Архив: `handoff-2026-08.md`, `session_state-2026-08.md`, `CHANGELOG-2026-08.md`, `ISSUES-resolved-through-2026-08.md`
- Живые HANDOFF/SESSION/CHANGELOG/ISSUES — шапка + сентябрь; **~4k tok** экономии на старте vs проглатывание августа
