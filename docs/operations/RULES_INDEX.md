# Индекс правил агента CoffeeOS

**Обновлено:** 2026-08-15 — PHASE 3 REVIEW канон в `spec-build-review` (push в фазе; deploy — апрув).

При конфликте приоритет: **`coffeeos-commit-ops`** > task-workflow > dev-gates > остальное.  
**Коммит:** канон CoffeeOS (commit после правок) **важнее** глобального User Rule «commit only when asked» — User Rule лучше удалить в Cursor Settings → Rules.  
**Субагенты:** таблица этапов в `agent-workflow`; карта — `docs/agents/SUBAGENTS.md`.  
**Команды:** `.cursor/commands/` + `.cursor/skills/` (human `/…`); цепочка start→spec→sbr→regress→review.  
**Hot-path / приёмка:** PHASE 3 (`spec-build-review`) → CI green → deploy (апрув) → `dev-gates` § пайплайн (Sentry+логи+MCP).

## Always (`alwaysApply: true`) — короткий закон

| Файл | Назначение |
|------|------------|
| `coffeeos-index.mdc` | Карта always vs on-demand |
| `workflow/coffeeos-commit-ops.mdc` | commit + ops всегда; push в PHASE 3 / иначе просьба; deploy — апрув |
| `workflow/coffeeos-agent-workflow.mdc` | Порядок шага + когда читать остальные |
| `project/coffeeos-core.mdc` | RLS, панели, enum, честность |
| `.cursorrules` | Краткий индекс корня |

## On-demand / globs — не каждый ход

| Файл | Когда |
|------|--------|
| `workflow/coffeeos-task-workflow.mdc` | Фича / CBR / CHECKLIST / отчёт / старт сессии |
| `workflow/spec-build-review.mdc` | SBR SPEC→RED→GREEN→REVIEW; **PHASE 3 канон** (local → 2 субагента → Entire → push/CI → стоп) |
| `workflow/coffeeos-dev-gates.mdc` | DoD, **пайплайн стенд**, регрессия зон, миграции, hot-path |
| `workflow/coffeeos-repo-layout.mdc` | Куда класть файлы; `scripts/scratch/` |
| `workflow/coffeeos-file-size-split.mdc` | Лимиты 50/120/200 (globs app) |
| `workflow/coffeeos-customer-intake.mdc` | PHASE 0: ТЗ заказчика → `customer_tasks/` |
| `workflow/coffeeos-context-hygiene.mdc` | `/ctx-trim` — архив ops, сжатие ISSUES; weekly пт–вс + 1–3 число месяца |
| `project/coffeeos-performance.mdc` | N+1 / SQL (globs `app|db|test|lib/**/*.rb`) |
| `project/coffeeos-services.mdc` | Сервис-объекты |
| `project/coffeeos-http.mdc` | Контроллеры, routes |
| `project/coffeeos-data.mdc` | models, migrate, schema |
| `project/coffeeos-ui.mdc` | views, frontend |
| `project/coffeeos-cart-sheet.mdc` | Shop CartSheet |
| `project/coffeeos-tests.mdc` | test/ |
| `project/coffeeos-code-review.mdc` | Ревью по запросу |
| `docs/integrations/INTEGRATIONS.md` (индекс ~45 строк) | Маршрут → `docs/integrations/*.md`; `@docs/integrations/INTEGRATIONS.md` + `/trace-bug` |
| `docs/operations/dev/ENTIRE.md` | Entire checkpoint ↔ commit; **обогащать обязательно** (пустой explain — стоп); Review/resume (on-demand) |

## Ops (память сессии)

| Файл | Когда |
|------|--------|
| `session/SESSION_STATE.md` / `HANDOFF.md` | Живые: **шапка** + текущий месяц. Старт: **только шапка** (`limit` до `---`); тело/PRACTICES/QA — не глотать |
| `session/archive/` | Старые месяцы — **не читать** без запроса |
| `journal/CHANGELOG.md` | Живой: писать в текущий месяц; на старте **не** читать весь файл |
| `journal/archive/` | Старые CHANGELOG-YYYY-MM — **не читать** без запроса |
| `ISSUES.md` | Баги; на старте — только **`## 🔴 Открыто`**; resolved → `issues/archive/` |
| CBR / `DEMO_FEEDBACK.md` | Заказчик, backlog — не на каждый старт |
| Folder `README.md` | Не читать при Glob/дереве; только по явной нужде |
| Skills / `ce-*` / субагенты | Фича/SBR — триггеры этапа; мелочь — без; карта: `docs/agents/SUBAGENTS.md` |
| Gem’ы / marketplace MCP | Без просьбы владельца — нет; оплата = `TbankAdapter`; приёмка = Point A |

## Дубликаты в `.cursor/rules/`

Корневые копии `coffeeos-{services,http,data,ui,tests,cart-sheet,code-review}.mdc` **удалены** (2026-09-02) — только `project/`.  
В корне остаётся **`coffeeos-index.mdc`** (always).
