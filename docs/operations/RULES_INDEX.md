# Индекс правил агента CoffeeOS

**Обновлено:** 2026-06-09. При конфликте приоритет у **workflow** (см. `coffeeos-dev-gates.mdc`).

## Workflow — `.cursor/rules/workflow/`

| Файл | Назначение |
|------|------------|
| `coffeeos-commit-ops.mdc` | **Канон:** commit + ops всегда (без вопроса); push только по явной просьбе |
| `coffeeos-task-workflow.mdc` | go, тесты, отчёт **Сделано \| Не сделано**, старт сессии, CHECKLIST/CBR |
| `coffeeos-agent-workflow.mdc` | Краткий порядок шага |
| `coffeeos-dev-gates.mdc` | DoD, регрессия по зонам, hot-path, миграции |
| `coffeeos-repo-layout.mdc` | Куда класть файлы; `scripts/scratch/` |
| `coffeeos-file-size-split.mdc` | Лимиты 50/120/200, сплит |
| `coffeeos-customer-intake.mdc` | PHASE 0: текст заказчика → док 1:1 в `customer_tasks/`, артефакты в `artifacts/<slug>/`, потом SPEC |

## Project — `.cursor/rules/project/`

| Файл | Назначение |
|------|------------|
| `coffeeos-core.mdc` | RLS, панели, enum, миграции (alwaysApply) |
| `coffeeos-performance.mdc` | N+1, SQL |
| `coffeeos-services.mdc` | Сервис-объекты |
| `coffeeos-http.mdc` | Контроллеры, routes |
| `coffeeos-data.mdc` | models, migrate, schema |
| `coffeeos-ui.mdc` | views, frontend |
| `coffeeos-tests.mdc` | test/ |
| `coffeeos-code-review.mdc` | Ревью по запросу |

## Ops (память сессии)

| Файл | Когда |
|------|--------|
| `session/SESSION_STATE.md` | После шага с правками |
| `session/HANDOFF.md` | Конец шага |
| `journal/CHANGELOG.md` | Заметные изменения |
| `ISSUES.md` | Баги |
| `milestones/veha_2/requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md` | Заказчик, backlog |
| `milestones/veha_2/requirements/DEMO_FEEDBACK.md` | Фидбек |

## Symlinks в `.cursor/rules/`

Файлы `coffeeos-*.mdc` в корне `rules/` — ссылки на `project/` для совместимости путей в старых доках и Cursor.
