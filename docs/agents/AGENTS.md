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
| **Always (короткий закон)** | `commit-ops`, `agent-workflow`, `project/coffeeos-core`, `coffeeos-index`, `.cursorrules` |
| **On-demand** | остальные `workflow/` + `project/` — по типу задачи (см. `RULES_INDEX.md`) |
| **Индекс** | `docs/operations/RULES_INDEX.md`, этот файл |

**При конфликте:** `coffeeos-commit-ops.mdc` **важнее** любых User Rules: **коммит всегда**; push на PHASE 3 — канон SBR; **deploy** — апрув.

## Цепочка задач (slash-команды)

| Команда | Когда |
|---------|-------|
| `/start` | Старт сессии (шапка ops + todo + `ISSUES` «🔴 Открыто») |
| `/spec` | SPEC + 2–7 файлов + hot-path «Не ломать»/«Проверка» |
| `/sbr` | RED → GREEN |
| `/regress` | Тесты зоны (Local) |
| `/review` | PHASE 3 канон: local → 2 субагента → Entire → push/CI → стоп (deploy — апрув) |
| `/trace-bug` | Диагностика hot-path интеграции до правок |

Карта: `.cursor/commands/README.md` · субагенты: `docs/agents/SUBAGENTS.md` · Entire: `docs/operations/dev/ENTIRE.md`

## Сервис-объекты (Веха 1)

Практика **только Service Objects**, без Domain Folders. Подробности: `.cursor/rules/project/coffeeos-services.mdc`, п. 9 — `coffeeos-core.mdc`.

| Ситуация | Действие |
|----------|----------|
| Заказ, склад, онбординг, оплата, 2+ модели | `app/services/{panel}/` |
| Простой index/show, одна модель, < ~15 строк | Можно в контроллере |
| Массовый рефакторинг | Только по апруву |

## Правила работы

- Продукт: `docs/product/01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`
- **Баги:** сразу `docs/operations/ISSUES.md` (секция «🔴 Открыто»)
- **Коммит:** всегда после шага с изменениями (до отчёта), **не спрашивать**
- **Новая задача:** `/start` → `/spec` → `/sbr` (намерение владельца = «ебашь/сделай/дальше»)
- Миграции / деструктивный git / deploy — **только явный апрув** владельца
- Scratch: `scripts/scratch/`, не корень репо

## Windows (локальная машина)

- **Entire CLI** и `entire checkpoint list` — только **WSL** (`/mnt/c/Tools/workarea/CoffeeOS`)
- **`entire enable`** — только из WSL (не PowerShell — мусорная папка в корне репо)
- **Регрессия:** не гонять полный `test/integration/shop/` на Windows — таргетные файлы из todo «Проверка» или CI
- Подробнее: `docs/operations/dev/ENTIRE.md` § Windows

## Дисциплина отчёта (контроль без скриптов)

Каждый шаг с правками — таблица **Сделано | Не сделано** + обязательно:

- `Коммит: <хеш>`
- `Субагент: …` (или `нет — мелочь`)
- Hot-path: **Local** · **Fly MCP** (Point A или skip + почему)

На `/review`: Entire `checkpoint explain <sha>` vs spec. Нет строки — шаг не `done`.

## Definition of Done

См. `coffeeos-dev-gates.mdc`: тесты зоны, ops, **Local + Fly MCP Point A** на hot-path.

**Не тащить:** gem’ы Tinkoff/Stripe, marketplace skills, RSpec — без просьбы. Оплата = `TbankAdapter`.

**MCP safety:** не OTP/PAN на профиле заказчика; приёмка не на Fly Test.
