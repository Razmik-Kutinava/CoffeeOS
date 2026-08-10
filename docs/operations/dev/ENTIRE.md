# Entire.io — слой Review/resume (CoffeeOS)

**Не заменяет** SBR, todo, HANDOFF, `customer_tasks/`. **Дополняет:** к Git-коммиту привязывается checkpoint AI (промпты, reasoning, tool calls).

**Канон путей Spec (без `docs/tasks/TASK-XX/`):**

| Шаблон заказчика | CoffeeOS |
|------------------|----------|
| `raw_spec.md` | `docs/operations/milestones/veha_2/requirements/customer_tasks/*.md` (текст 1:1) |
| `plan.md` | `docs/operations/session/todo.md` |
| `spec` / артефакты | CBR + `docs/operations/milestones/veha_2/artifacts/<slug>/` |
| интеграции SSOT | `docs/integrations/INTEGRATIONS.md` → один секционный `docs/integrations/*.md` |
| код | `app/`, `test/` (не `src/`) |

---

## Слои (что поверх чего)

```
Review (PM)     → bugbot + Fly Point A + Entire why-context
Entire          → checkpoint ↔ commit (Cursor hooks + git commit)
Cursor + rules  → SBR, /spec /sbr /review, commit-ops
Docs (Spec)     → customer_tasks, todo, artifacts, docs/integrations/
Git             → develop → staging → main
```

Entire **не меняет** порядок шага. Checkpoint появляется, когда после работы агента в Cursor сделан **`git commit`** (RED/GREEN/docs — как в `coffeeos-commit-ops`).

---

## One-time setup (WSL)

```bash
curl -fsSL https://entire.io/install.sh | bash   # ~/.local/bin/entire
cd /mnt/c/Tools/workarea/CoffeeOS              # только WSL-путь, не C:\ из PowerShell
entire enable -y --agent cursor
entire status   # ● Enabled · Agents · Cursor
```

**Windows:** `entire enable` из PowerShell может создать мусорную папку `C:\Tools\...\.git\hooks` в корне репо — включать **из WSL**. Git hooks должны лежать в `.git/hooks/` (commit-msg, post-commit, …).

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
- `@docs/integrations/INTEGRATIONS.md` + секция — для hot-path: агент читал bridge, не выдумал endpoint?

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

1. `entire status` → **● Enabled · Agents · Cursor**
2. `.git/hooks/` содержит `post-commit`, `commit-msg` (после `entire enable` из WSL)
3. После **agent-сессии в Cursor** + **`git commit`**: `entire checkpoint list` → ≥1 checkpoint
4. `entire checkpoint explain <sha>` — не пустой (не «0 lines»)

**0 checkpoints сразу после enable — норма.** Checkpoint появляется после первого commit в agent-сессии, не от enable.

---

## Windows (обязательно для CoffeeOS)

| Действие | Где |
|----------|-----|
| `entire enable`, `entire status`, `checkpoint list/explain` | **WSL** (`/mnt/c/Tools/workarea/CoffeeOS`) |
| Git hooks Entire | `.git/hooks/` — ставятся только через WSL enable |
| Cursor hooks (`.cursor/hooks.json`) | `sh -c` — нужен sh (Git Bash/WSL); без `entire` в PATH — тихий skip |
| **Запрещено** | `entire enable` из **PowerShell** — создаёт мусорную папку `C:…Tools…CoffeeOS.git.hooks` в корне репо (удалить вручную) |
| **Git commit из Windows** | Hook пишет `Entire CLI … not on PATH. Skipping` — checkpoint **не** создаётся. Варианты: (1) установить Entire CLI в Windows PATH; (2) `wsl git commit` из WSL; (3) checkpoint всё равно может прийти от **Cursor hooks** при agent-сессии + commit |

**Проверка hook:** после commit смотри вывод git — если `Skipping Entire Git hook`, checkpoint только через Cursor session hooks (нужна активная agent-сессия в Cursor до commit).

**Регрессия на Windows:** не гонять полный `test/integration/shop/` — зависает (см. ISSUES). Таргетные файлы из todo «Проверка» или CI.

**User Rules в Cursor:** глобального «commit only on ask» может не быть в UI — канон CoffeeOS (`commit-ops`) всё равно **важнее**: commit после каждого шага без вопроса.

*2026-08-10 · enabled cursor · git-refs backend*
