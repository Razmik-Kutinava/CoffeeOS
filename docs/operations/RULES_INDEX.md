# Индекс правил агента CoffeeOS

**Обновлено:** 2026-08-09 — slash-команды `/start`…`/review` (+ умный start, `Next: /…`).

При конфликте приоритет: **`coffeeos-commit-ops`** > task-workflow > dev-gates > остальное.  
**Коммит:** канон CoffeeOS (commit после правок) **важнее** глобального User Rule «commit only when asked» — User Rule лучше удалить в Cursor Settings → Rules.  
**Субагенты:** таблица этапов в `agent-workflow`; карта — `docs/agents/SUBAGENTS.md`.  
**Команды:** `.cursor/commands/` + `.cursor/skills/` (human `/…`); цепочка start→spec→sbr→regress→review.

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
| `workflow/spec-build-review.mdc` | SBR SPEC→RED→GREEN→REVIEW; в SPEC — 2–7 файлов в todo; BUILD без `@codebase` зря |
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
| `session/SESSION_STATE.md` / `HANDOFF.md` | Живые: **шапка** + текущий месяц. Старт: **только шапка** (`limit` до `---`); тело/PRACTICES/QA — не глотать |
| `session/archive/` | Старые месяцы — **не читать** без запроса |
| `journal/CHANGELOG.md` | Живой: писать в текущий месяц; на старте **не** читать весь файл |
| `journal/archive/` | Старые CHANGELOG-YYYY-MM — **не читать** без запроса |
| `ISSUES.md` | Баги; на старте — только 🔴 (архив позже, если файл раздуется) |
| CBR / `DEMO_FEEDBACK.md` | Заказчик, backlog — не на каждый старт |
| Folder `README.md` | Не читать при Glob/дереве; только по явной нужде |
| Skills / `ce-*` / субагенты | Фича/SBR — триггеры этапа; мелочь — без; карта: `docs/agents/SUBAGENTS.md` |

## Symlinks в `.cursor/rules/`

Оставлен `coffeeos-code-review.mdc` → `project/` (совместимость).  
Симлинки `coffeeos-core` / `coffeeos-performance` **удалены** — Cursor дублировал их в always-контекст.
