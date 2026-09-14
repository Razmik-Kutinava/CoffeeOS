# /unlazy — acceptance ledger (CoffeeOS)

Substantial work only. Канон: `docs/operations/dev/unlazy/README.md` · skill `.agents/skills/unlazy/SKILL.md`.  
Checker: `node .agents/skills/unlazy/scripts/gate-check.mjs`.

**Не** заменяет SBR / commit-ops / dev-gates. **Не** ставь Stop-hook. **Не** Depth Tree без явного `tree N`.

## Когда
Фича / hot-path / веха / «доделай». Мелочь → стоп, скажи «unlazy не нужен».

## Сделай
1. Если нет ledger — скопируй `docs/operations/dev/unlazy/GATES.template.md` → `docs/operations/session/GATES.md` (или путь из todo). Заполни 3–8 gates: тест изменения, регрессия зоны, (hot-path) Fly MCP manual/skip.
2. `node .agents/skills/unlazy/scripts/gate-check.mjs --status <ledger>`
3. Прочитай каждый `CHECK:` / скрипт. Затем `--approve`, перед закрытием — `--reverify`.
4. Отчёт: met / unmet / abandoned по evidence. Local | Fly MCP как в CoffeeOS.
5. Коммит + ops по `coffeeos-commit-ops` (ledger в git только если осознанно; иначе session `GATES.md` + ignore по решению).

## Токены
Не читай `UPSTREAM_SKILL.md`, `references/method|orchestration|dispatch|parallel`, `research/` — пока нет `tree N`.

## Обязательно в конце

Если ledger готов и ждём код:

`Next: /sbr`

Если gates зелёные после GREEN:

`Next: /regress`

Если после regress:

`Next: /review`
