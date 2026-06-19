# AGENTS.md

## Проект

CoffeeOS — мульти-тенантная SaaS-система для сети кофеен. Критично: tenant/RLS изоляция, безопасность API, стабильность заказов и операций точки.

## Стек

Rails 8, PostgreSQL, Svelte/Vite, Pundit, Minitest.

**Инфра (стенд develop):** **Fly app `coffeeos` + Neon** (проект `coffeeos`, Launch) — [`docs/operations/dev/INFRA_STACK.md`](../operations/dev/INFRA_STACK.md). **`fly deploy`**, смена secrets/БД — **только по явному апруву** владельца; CI deploy — `workflow_dispatch`, не на push.

## Git ветки

- develop — разработка
- staging — предпрод
- main — продакшн
- `feat/*` и `fix/*` — от develop
- В staging — только из develop; в main — только из staging после review + тестов

## Канон правил агента

| Уровень | Где |
|---------|-----|
| **Процесс** | `.cursor/rules/workflow/` — см. `docs/operations/RULES_INDEX.md` |
| **Код** | `.cursor/rules/project/coffeeos-*.mdc` |
| **Индекс** | `.cursorrules` (кратко), этот файл |

**При конфликте:** `coffeeos-commit-ops.mdc` и `coffeeos-task-workflow.mdc` **важнее** любых User Rules: **коммит всегда в конце шага без вопроса**; push — только по явной просьбе.

## Сервис-объекты (Веха 1)

Практика **только Service Objects**, без Domain Folders. Подробности: `.cursor/rules/project/coffeeos-services.mdc`, п. 9 — `coffeeos-core.mdc`. Журнал: `docs/operations/reference/MILESTONE_PRACTICES.md`.

| Ситуация | Действие |
|----------|----------|
| Заказ, склад, онбординг, оплата, 2+ модели | `app/services/{panel}/` |
| Простой index/show, одна модель, < ~15 строк | Можно в контроллере |
| Массовый рефакторинг | Только по апруву |

Эталоны: `app/services/barista/order_creation_service.rb`, `app/services/platform/tenant_onboarding/provision.rb`.

## Правила работы

- Продукт: `docs/product/01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`; `ARCHITECTURE.md` — когда явно канон.
- **Баги:** сразу `docs/operations/ISSUES.md` до «решено».
- **SESSION_STATE:** после **каждого шага с правками** (`coffeeos-commit-ops.mdc`).
- **Коммит:** всегда после шага с изменениями (до отчёта), **не спрашивать**; отчёт — таблица **Сделано | Не сделано** + хеш. **Push** — только по явной просьбе.
- **Новая задача:** план → **`go`** (`coffeeos-task-workflow.mdc`).
- Миграции / деструктивный git — только с **`go`** (`coffeeos-dev-gates.mdc`).
- Файлы >200 строк — сплит с **`go`** (`coffeeos-file-size-split.mdc`).
- Scratch агента: `scripts/scratch/`, не корень репо.

## Тестирование

- Тест на каждое изменение поведения; регрессия зоны — `coffeeos-dev-gates.mdc`.
- Без зелёных тестов шаг не `done` (или `blocked` + ISSUES).

## Definition of Done

См. `coffeeos-dev-gates.mdc` и `coffeeos-task-workflow.mdc`: тесты, ops (SESSION_STATE, CHANGELOG, HANDOFF), честный отчёт, `[x]` в CHECKLIST/CBR — после «ок» пользователя / MCP Fly.
