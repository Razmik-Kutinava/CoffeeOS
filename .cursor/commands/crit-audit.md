# /crit-audit — аудит критических ошибок (конечный)

**Канон (не дублировать):** [`coffeeos-critical-audit.mdc`](../rules/workflow/coffeeos-critical-audit.mdc) · журнал [`CRITICAL_LEDGER.md`](../../docs/operations/dev/CRITICAL_LEDGER.md).

Автоматически вызывается в `/review` (шаг 2). Вручную — когда хочешь проверить.

## Сделай

1. Прочитай шапку и таблицы `CRITICAL_LEDGER.md`. Scope = `git diff <last_audited_sha>..HEAD` (app/ lib/ db/ config/ frontend/). «полный аудит» в запросе → весь hot-path по зонам.
2. Дифф пустой → гейты → `CLEAN`, стоп. Не искать «ещё что-нибудь».
3. Ищи **только** C1–C5. Уже в журнале → пропусти (кроме нового диффа по тем же строкам + новый тест).
4. Каждый кандидат → падающий тест (≤2 попытки). Нет теста → `rejected: no-repro`. Есть → RED-коммит `test: CA-NNN … [RED]`, статус `open`. Сказали «чини» → GREEN `fix: CA-NNN … [GREEN]`, статус `fixed`.
5. Гейты: CI на HEAD (`gh run list -L 1`) · `bin/smoke` · Fly MCP Point A (только если дифф трогает hot-path).
6. Вердикт `CLEAN` / `BLOCKED: N` по § 6 канона. Мнение без теста вердикт не меняет.
7. Обнови журнал: строки находок, «История аудитов», шапку (`last_audited_sha` = HEAD, дата, вердикт). Commit + ops.

Отчёт — формат § 7 канона.

## Обязательно в конце

`CLEAN` в `/review` → `Next: продолжить /review (Entire → push)`  
`CLEAN` вручную → `Next: /review` или работа дальше  
`BLOCKED: N` → `Next: /sbr` (чинить CA-…)
