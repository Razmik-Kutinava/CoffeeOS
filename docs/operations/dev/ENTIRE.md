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
Review (PM)     → PHASE 3 SBR (2 субагента + Entire + CI); Fly Point A после deploy
Entire          → checkpoint ↔ commit (Cursor hooks + git commit)
Cursor + rules  → SBR, /spec /sbr /review, commit-ops
Docs (Spec)     → customer_tasks, todo, artifacts, docs/integrations/
Git             → develop → staging → main
```

Entire **не меняет** порядок шага. Checkpoint появляется, когда после работы агента в Cursor сделан **`git commit`** (RED/GREEN/docs — как в `coffeeos-commit-ops`).

---

## Закон: обогащать Entire (не галочка)

**Обогатить** = why-context (промпты, файлы, tool calls) **записан** в checkpoint: `entire checkpoint explain <sha>` **не пустой**.

**Запрещено** (это не ревью):

- «Entire: spec vs todo/shop-api OK» при `no trailer` / empty explain
- «hook skip Windows» и идти на push
- PHASE 3 шаг 3 закрыт без **checkpoint id**

После RED/GREEN/docs-коммита задачи (SBR, не typo одного файла):

1. `entire checkpoint explain <sha>` (или `HEAD`)
2. Пусто / `no Entire-Checkpoint trailer` → **стоп, не push.**  
   `entire session attach <cursor-session-id> --agent cursor` на **ещё не запушенный** коммит. Уже на `origin` GREEN **не** `--amend` / не `--force` rewrite — тогда docs-коммит + attach (как backfill #64–#68).
3. Отчёт: **`Entire: <checkpoint-id> на <sha>`**. Без id шаг не `done`.

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
| **2 BUILD** | `/sbr` RED→GREEN → **commit** | checkpoint на commit; `explain HEAD` не пустой |
| **3 REVIEW** | `/review` = SBR PHASE 3 (оба субагента → Entire → push/CI) | `explain <sha>` не пустой **до** push; иначе attach |
| **Resume** | новый чат / засорился контекст | `entire session resume <branch>` |

### REVIEW — проверка why-context

После последнего GREEN (или docs) коммита задачи. **Сначала enrichment, потом сверка spec.** Empty explain = шаг 3 не пройден → не шаг 4 push.

```bash
entire checkpoint list
entire checkpoint explain <commit-sha>    # не пустой: промпты, файлы, tool calls
```

Пусто → attach (закон выше), потом снова `explain`. Только после этого сверить:

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
4. `entire checkpoint explain <sha>` — не пустой (не «0 lines» / не `no trailer`)
5. В отчёте `/review` есть **`Entire: <id> на <sha>`** — не «spec OK» без id

**0 checkpoints сразу после enable — норма.** Checkpoint появляется после первого commit в agent-сессии, не от enable. Enable ≠ обогащение.

---

## Windows (обязательно для CoffeeOS)

| Действие | Где |
|----------|-----|
| `entire enable`, `entire status`, `checkpoint list/explain` | **WSL** (`/mnt/c/Tools/workarea/CoffeeOS`) |
| Git hooks Entire | `.git/hooks/` — ставятся только через WSL enable |
| Cursor hooks (`.cursor/hooks.json`) | `sh -c` — нужен sh (Git Bash/WSL); без `entire` в PATH — тихий skip |
| **Запрещено** | `entire enable` из **PowerShell** — создаёт мусорную папку `C:…Tools…CoffeeOS.git.hooks` в корне репо (удалить вручную) |
| **Git commit из Windows** | Hook пишет `Entire CLI … not on PATH. Skipping` — checkpoint **не** создаётся. **Фикс:** native CLI в PATH: `scoop bucket add entire https://github.com/entireio/scoop-bucket.git` · `scoop install entire/cli` (shim `~\scoop\shims\entire`). Затем `git` из Windows видит `entire` в commit-msg. Альтернативы: `wsl git commit`; или Cursor hooks при `entire` в PATH. `entire enable` — только WSL. |

**Проверка hook:** после commit смотри вывод git — если `Skipping Entire Git hook`, checkpoint только через Cursor session hooks (нужна активная agent-сессия в Cursor до commit).

**WSL + Cursor transcripts (2026-08-26 #71):** Entire CLI в WSL ищет `~/.cursor/projects/.../agent-transcripts/`. На Windows Cursor пишет в `/mnt/c/Users/<user>/.cursor/...`. Без symlink attach → `transcript not found`. Фикс один раз:

```bash
ln -sfn /mnt/c/Users/$USER/.cursor ~/.cursor   # в WSL; путь Windows-user при необходимости поправить
entire session attach <session-id> --agent cursor --force
entire checkpoint explain <id|HEAD>            # не пустой
```

**Регрессия на Windows:** не гонять полный `test/integration/shop/` — зависает (см. ISSUES). Таргетные файлы из todo «Проверка» или CI.

**User Rules в Cursor:** глобального «commit only on ask» может не быть в UI — канон CoffeeOS (`commit-ops`) всё равно **важнее**: commit после каждого шага без вопроса.

## Backfill #64–#68 (Telegram / Instagram → `/shop`)

GREEN SHA **не переписываем** (уже на `origin/develop`, hook тогда skip). Why-context ловим **attach сессий** на docs-коммит backfill + поиск `entire checkpoint search`.

**Эндпоинты:** новых нет. Канон: `GET /shop?tenant_id=` → `GET /shop/api/categories?tenant_id=`. Bridge: [`shop-api.md`](../../integrations/shop-api.md) § Embedded browser · WebView runtime · UI · UX/perf.

| CBR | GREEN (без trailer) | Cursor session | Spec / shop-api |
|-----|---------------------|----------------|-----------------|
| #64 boot watchdog | `ed324b20` | `f6ad5bfa-b451-4447-bcd2-d347bbc5c1c3` | Embedded browser · skeleton |
| #65 tenant linkage | `89ecfaf7` | `f141e171-bb87-46b2-9cd1-bcae7466a739` | query > meta; blank key = ошибка |
| #66 WebView runtime | `ca9c5834` | `8b384332-afc2-4a25-93b1-5c11264df863` | `shopWebView.js`; не Bot/Mini App |
| #67 WebView UI | `8daadddf` | `7b9bead5-11c5-4849-8092-81e48220de71` | layout; без backend endpoints |
| #68 UX/perf | `ff9374d1` | `7851e58b-593c-4e43-b9c1-2784bc831eeb` | SWR/lazy/retry; без backend endpoints |

```bash
# после docs-коммита backfill (не --force на уже запушенных GREEN)
entire session attach <session-id> --agent cursor
entire checkpoint search "Telegram WebView"
entire checkpoint explain <backfill-sha>
```

`entire explain <GREEN-sha>` по-прежнему пустой (нет trailer) — смотри backfill-SHA / search.

*2026-08-15 · backfill #64–#68 attach · scoop `entire/cli` 0.8.42*
*2026-08-10 · enabled cursor · git-refs backend*
