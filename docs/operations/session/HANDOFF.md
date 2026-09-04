# HANDOFF — Веха 2

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-04 (CI scan_js retry)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| CI importmap audit retry ×3 | CI green → deploy апрув · Fly MCP |

**last_done:** fix(ci) retry `bin/importmap audit` на npm ReadTimeout  
**next_step:** дождаться CI green; deploy только по апруву

**ctx_trim:** `2026-09-02`

**Архив session:** [`archive/README.md`](archive/README.md) — incl. `todo-shift-close-2026-09.md`  
**Архив journal:** [`../journal/archive/README.md`](../journal/archive/README.md)

---

## Текущий месяц (2026-09)

### ctx-trim токенов (2026-09-02)

| Что | Статус |
|-----|--------|
| 7 дублей `.cursor/rules/coffeeos-*.mdc` | удалены (остался `project/`) |
| always-бандл index + agent-workflow + `.cursorrules` | сжат |
| `todo.md` shift-close | stub · полный → `archive/todo-shift-close-2026-09.md` |
| ISSUES 🔴 | короткая таблица ID/статус |
| `coffeeos-performance` globs | без `test/**` (есть `coffeeos-tests`) |

### uploads gitignore (2026-09-01)

| Что | Статус |
|-----|--------|
| `.gitignore` — убран `!/public/uploads/products/` | **done** |
| Локальные тест-файлы `public/uploads/products/*` | **удалены** (15 шт.) |
