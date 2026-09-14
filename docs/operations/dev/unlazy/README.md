# Unlazy в CoffeeOS

**Источник:** [Leonxlnx/unlazy](https://github.com/Leonxlnx/unlazy) (pin: `skills-lock.json`).  
**Установка:** `npx skills add Leonxlnx/unlazy -y` → vendor `.agents/skills/unlazy/`.  
**Вход:** `/unlazy` · thin skill (не авто-invocation).

## Берём

| Да | Нет |
|----|-----|
| Solo ledger `GATES.md` | Claude Stop-hook |
| `gate-check.mjs` `--status` / `--approve` / `--reverify` | Depth Tree / parallel по умолчанию |
| Evidence в отчёте | Замена SBR / commit-ops / Fly MCP DoD |

## Быстрый старт

```powershell
copy docs\operations\dev\unlazy\GATES.template.md docs\operations\session\GATES.md
# заполни CHECK/EXPECT из coffeeos-dev-gates
node .agents/skills/unlazy/scripts/gate-check.mjs --status docs/operations/session/GATES.md
node .agents/skills/unlazy/scripts/gate-check.mjs --approve docs/operations/session/GATES.md
node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/session/GATES.md
```

Smoke install:

```powershell
node .agents/skills/unlazy/scripts/gate-check.mjs --status docs/operations/dev/unlazy/GATES.smoke.md
node .agents/skills/unlazy/scripts/gate-check.mjs --approve docs/operations/dev/unlazy/GATES.smoke.md
```

Approvals: `~/.unlazy/approved` (вне репо). Runtime: `.unlazy/`, `.unlazy-hook-state.json` — в `.gitignore`.

## Токены

По умолчанию Solo. `UPSTREAM_SKILL.md` + orchestration — только по явному `tree N`.
