---
name: unlazy
description: "CoffeeOS /unlazy — ledger приёмки + gate-check. Substantial work only. Вызывать через /unlazy. Не авто-триггер."
disable-model-invocation: true
---

# Unlazy (CoffeeOS overlay)

Дисциплина доказательств поверх SBR. **Не** заменяет `coffeeos-commit-ops` / `coffeeos-dev-gates` / SBR.

Полный upstream: `UPSTREAM_SKILL.md` + `references/` — читать **только** если пользователь явно сказал `tree N` / orchestrated / parallel.

## Когда

- Substantial: фича, hot-path, веха, «доделай до конца».
- **Не** для мелочи (typo, 1–3 файла, docs-only).

## Режим по умолчанию: Solo (дёшево по токенам)

1. Скопируй `docs/operations/dev/unlazy/GATES.template.md` → `GATES.md` в корне задачи **или** `docs/operations/session/GATES.md` (одна задача = один ledger).
2. 3–8 gates из CoffeeOS DoD. Команды — из `coffeeos-dev-gates` / todo «Проверка». Portable: Node-скрипты репо; на Windows не полагайся на `grep`/`tail`.
3. Статус без исполнения:

```text
node .agents/skills/unlazy/scripts/gate-check.mjs --status GATES.md
```

4. Прочитай каждый `CHECK:`. Потом:

```text
node .agents/skills/unlazy/scripts/gate-check.mjs --approve GATES.md
```

5. Перед «готово» / REVIEW:

```text
node .agents/skills/unlazy/scripts/gate-check.mjs --reverify GATES.md
```

6. В отчёте: met / unmet / abandoned **только по evidence**. Hot-path: Local + Fly MCP Point A — отдельные gates или manual с evidence.

## Запрещено без явной просьбы

- Claude Stop-hook (`install-hooks.mjs`)
- Depth Tree / `.unlazy/<scope>/` parallel dispatch / `--jobs` fan-out
- Читать весь `UPSTREAM_SKILL.md` + research на мелочь

## Приоритет

`coffeeos-commit-ops` > task-workflow > `coffeeos-dev-gates` > этот skill.
Commit + SESSION_STATE/CHANGELOG/HANDOFF — как обычно в CoffeeOS.

Канон: `docs/operations/dev/unlazy/README.md` · команда `/unlazy`.
