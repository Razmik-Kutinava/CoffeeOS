# /review — PHASE 3 REVIEW

**Канон (не дублировать):** [`spec-build-review.mdc`](../rules/workflow/spec-build-review.mdc) § PHASE 3.

Порядок: local → `bugbot`+`security-review` + **`/crit-audit`** ([`crit-audit.md`](crit-audit.md); находки субагентов фильтруются по C1–C5 + падающий тест, вердикт `CLEAN` обязателен) → Entire (`explain` не пустой, иначе attach, не push) → push/CI (логи, чин, снова push) → **CI green → стоп**. Deploy — апрув владельца.

## COMPONENT_MAP (после зелёных тестов)

Решение и правило правки — [`TASK_PATCH.md`](../../docs/operations/dev/TASK_PATCH.md) шаг 6: сначала «Обновление требуется: да/нет — причина» (критерии 6.0), при «да» — только строки таблицы `docs/operations/session/COMPONENT_MAP.md`, отдельный docs-коммит `docs: update COMPONENT_MAP — [компоненты]`. При «нет» карту не читать целиком и не править.

## Очередь Push + SMS

Шаг из [`PUSH_SMS_QUEUE.md`](../../docs/operations/milestones/veha_2/requirements/PUSH_SMS_QUEUE.md) → после CI green закрыть шаг по разделу «Как работать» п. 9 (статус `done`, HANDOFF «Следующий шаг», строки `Next`).

## Обязательно в конце (копипаст)

`Next: deploy — только по апруву владельца`

Шаг очереди Push + SMS — вместо строки выше: `Next: 🚀 деплой N — по апруву владельца` (если после шага стоит 🚀), затем последней строкой `Next (новый чат): /start → шаг <№> — <ID> <название>`.

Дыры до push: `Next: /sbr`
