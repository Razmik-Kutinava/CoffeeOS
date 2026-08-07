# Индекс правил агента CoffeeOS

**Обновлено:** 2026-08-07 — thin always (меньше токенов, без потери канона).

При конфликте приоритет: **`coffeeos-commit-ops`** > task-workflow > dev-gates > остальное.

## Always (`alwaysApply: true`) — короткий закон

| Файл | Назначение |
|------|------------|
| `coffeeos-index.mdc` | Карта always vs on-demand |
| `workflow/coffeeos-commit-ops.mdc` | commit + ops всегда; push только по просьбе |
| `workflow/coffeeos-agent-workflow.mdc` | Порядок шага + когда читать остальные |
| `project/coffeeos-core.mdc` | RLS, панели, enum, честность |
| `.cursorrules` | Краткий индекс корня |

## On-demand / globs — не каждый ход

| Файл | Когда |
|------|--------|
| `workflow/coffeeos-task-workflow.mdc` | Фича / CBR / CHECKLIST / отчёт / старт сессии |
| `workflow/spec-build-review.mdc` | SBR SPEC→RED→GREEN→REVIEW |
| `workflow/coffeeos-dev-gates.mdc` | DoD, регрессия зон, миграции, hot-path |
| `workflow/coffeeos-repo-layout.mdc` | Куда класть файлы; `scripts/scratch/` |
| `workflow/coffeeos-file-size-split.mdc` | Лимиты 50/120/200 (globs app) |
| `workflow/coffeeos-customer-intake.mdc` | PHASE 0: ТЗ заказчика → `customer_tasks/` |
| `project/coffeeos-performance.mdc` | N+1 / SQL (globs `app|db|test|lib/**/*.rb`) |
| `project/coffeeos-services.mdc` | Сервис-объекты |
| `project/coffeeos-http.mdc` | Контроллеры, routes |
| `project/coffeeos-data.mdc` | models, migrate, schema |
| `project/coffeeos-ui.mdc` | views, frontend |
| `project/coffeeos-cart-sheet.mdc` | Shop CartSheet |
| `project/coffeeos-tests.mdc` | test/ |
| `project/coffeeos-code-review.mdc` | Ревью по запросу |

## Ops (память сессии)

| Файл | Когда |
|------|--------|
| `session/SESSION_STATE.md` | После шага с правками (читай **верх**, не всю историю) |
| `session/HANDOFF.md` | Конец шага (читай **верх**) |
| `journal/CHANGELOG.md` | Заметные изменения |
| `ISSUES.md` | Баги |
| CBR / `DEMO_FEEDBACK.md` | Заказчик, backlog |

## Symlinks в `.cursor/rules/`

Оставлен `coffeeos-code-review.mdc` → `project/` (совместимость).  
Симлинки `coffeeos-core` / `coffeeos-performance` **удалены** — Cursor дублировал их в always-контекст.
