# Entire.io — слой Review/resume (CoffeeOS)

**Не заменяет** SBR, todo, HANDOFF, `customer_tasks/`. **Дополняет:** к Git-коммиту привязывается checkpoint AI (промпты, reasoning, tool calls).

**Канон путей Spec (без `docs/tasks/TASK-XX/`):**

| Шаблон заказчика | CoffeeOS |
|------------------|----------|
| `raw_spec.md` | `docs/operations/milestones/veha_2/requirements/customer_tasks/*.md` (текст 1:1) |
| `plan.md` | `docs/operations/session/todo.md` |
| `spec` / артефакты | CBR + `docs/operations/milestones/veha_2/artifacts/<slug>/` |
| интеграции SSOT | `INTEGRATIONS.md` → один `docs/integrations/*.md` |
| код | `app/`, `test/` (не `src/`) |

---

## Слои (что поверх чего)

```
Review (PM)     → bugbot + Fly Point A + Entire why-context
Entire          → checkpoint ↔ commit (Cursor hooks + git commit)
Cursor + rules  → SBR, /spec /sbr /review, commit-ops
Docs (Spec)     → customer_tasks, todo, artifacts, INTEGRATIONS
Git             → develop → staging → main
```

Entire **не меняет** порядок шага. Checkpoint появляется, когда после работы агента в Cursor сделан **`git commit`** (RED/GREEN/docs — как в `coffeeos-commit-ops`).

---

## One-time setup (WSL)

```bash
curl -fsSL https://entire.io/install.sh | bash   # ~/.local/bin/entire
cd /mnt/c/Tools/workarea/CoffeeOS
entire enable -y --agent cursor
entire status   # ● Enabled · Agents · Cursor
```

В репо коммитятся: `.entire/settings.json`, `.entire/.gitignore`. Локально (не в git): `.entire/settings.local.json`, `tmp/`, `logs/`.

---

## Workflow по фазам SBR

| Фаза | CoffeeOS | Entire |
|------|----------|--------|
| **0 Intake** | `customer_tasks/` + `artifacts/` | — |
| **1 SPEC** | `/spec` → `todo.md` | — |
| **2 BUILD** | `/sbr` RED→GREEN → **commit** | checkpoint на commit |
| **3 REVIEW** | `/review` + bugbot | `entire checkpoint explain <sha>` |
| **Resume** | новый чат / засорился контекст | `entire session resume <branch>` |

### REVIEW — проверка why-context

После последнего GREEN (или docs) коммита задачи:

```bash
entire checkpoint list
entire checkpoint explain <commit-sha>    # промпты, файлы, tool calls
```

Сверить с:
- `customer_tasks/<задача>.md` — все пункты ТЗ?
- `todo.md` — «Не ломать», «Проверка»?
- `@INTEGRATIONS.md` + секция — для hot-path: агент читал bridge, не выдумал endpoint?

### Resume — точечные правки после ревью

```bash
entire session resume develop    # или feature-ветка
# точечный промпт в Cursor: «измени X, не трогай Y»
git commit -m "fix: … по ревью"
```

---

## Полезные команды

```bash
entire status
entire session current
entire checkpoint search "tbank webhook"
entire checkpoint tokens <id>
entire agent-help          # не угадывать флаги
```

CLI: WSL, `PATH=$HOME/.local/bin:$PATH`. На Windows без WSL — установить Entire отдельно или работать через WSL для checkpoint-команд.

---

## Безопасность

- Checkpoint может содержать фрагменты логов, обсуждение интеграций — **не** prod secrets в промптах.
- Не портить профиль заказчика тестовым OTP (канон Point A / DEMO_LOGINS).
- `push` checkpoint-веток — по политике команды; **push кода** — только по явной просьбе владельца.

---

## Критерий «Entire работает»

После commit с кодом: `entire checkpoint list` показывает checkpoint; `explain` — не пустой (не «0 lines» как у чистого чата без commit).

*2026-08-10 · enabled cursor · git-refs backend*
