# `.cursor` — что здесь лежит

Папка настроек Cursor для CoffeeOS. Полная карта правил: `docs/operations/RULES_INDEX.md`.

## Дерево

```
.cursor/
├── README.md                 ← этот файл
├── CURSOR_RULES_REPORT.txt   ← короткий отчёт/снимок структуры (legacy)
└── rules/                    ← правила агента (*.mdc)
    ├── coffeeos-index.mdc    ← индекс always vs on-demand (always)
    ├── coffeeos-*.mdc        ← symlinks → project/ (старые пути)
    ├── workflow/             ← КАК работать (процесс)
    └── project/              ← КАК писать код (домен)
```

---

## `rules/workflow/` — процесс

| Файл | Простыми словами |
|------|------------------|
| `coffeeos-commit-ops.mdc` | **Always.** Коммит + ops сам; push только по просьбе |
| `coffeeos-agent-workflow.mdc` | **Always.** Порядок шага; старт = шапка памяти; список файлов в SPEC |
| `coffeeos-task-workflow.mdc` | Фичи / отчёт Сделано\|Не сделано / старт сессии |
| `spec-build-review.mdc` | SBR: SPEC → RED → GREEN → REVIEW |
| `coffeeos-dev-gates.mdc` | Тесты, регрессия зон, миграции |
| `coffeeos-repo-layout.mdc` | Куда класть файлы в репо |
| `coffeeos-file-size-split.mdc` | Лимиты размера файлов / сплит |
| `coffeeos-customer-intake.mdc` | PHASE 0: ТЗ заказчика → доки 1:1 |

---

## `rules/project/` — код

| Файл | Простыми словами |
|------|------------------|
| `coffeeos-core.mdc` | **Always.** Tenant / RLS / панели |
| `coffeeos-performance.mdc` | N+1, SQL (подтягивается на Ruby) |
| `coffeeos-services.mdc` | Сервис-объекты |
| `coffeeos-http.mdc` | Контроллеры, роуты |
| `coffeeos-data.mdc` | Модели, миграции, схема |
| `coffeeos-ui.mdc` | Views / frontend |
| `coffeeos-cart-sheet.mdc` | Шторка корзины shop |
| `coffeeos-tests.mdc` | Minitest |
| `coffeeos-code-review.mdc` | Ревью по запросу |

---

## Корень `rules/`

| Файл | Зачем |
|------|--------|
| `coffeeos-index.mdc` | Карта: что always, что читать по задаче |
| `coffeeos-*.mdc` (остальные) | Ссылки на `project/` — для старых путей; канон в `project/` |

---

## Рядом (не в `.cursor`, но важно)

| Файл | Зачем |
|------|--------|
| `.cursorrules` (корень репо) | Короткий always-индекс |
| `docs/operations/RULES_INDEX.md` | Человекочитаемая карта |
| `docs/agents/AGENTS.md` | Как агенту жить в проекте |

**Always сейчас:** index, commit-ops, agent-workflow, core, `.cursorrules`.  
Остальное — по задаче / globs.
