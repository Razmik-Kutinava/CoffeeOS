# CRITICAL_LEDGER — журнал аудита критических ошибок

Канон: [`.cursor/rules/workflow/coffeeos-critical-audit.mdc`](../../../.cursor/rules/workflow/coffeeos-critical-audit.mdc) · команда `/crit-audit`.

> Новый чат: прочитать шапку + таблицу. Находки со статусом `fixed` / `rejected` / `accepted-risk` **не повторять**.

## Шапка

**last_audited_sha:** `dd072f3f` (код = `0a3ac0db` / Fly v504)  
**last_audit_date:** 2026-09-29  
**last_verdict:** `CLEAN` (пустой дифф кода; baseline, не полный аудит)

## Статусы

`open` — воспроизведено тестом, не исправлено · `fixed` — тест зелёный после фикса · `rejected: no-repro` — тест не удалось написать · `rejected: not-critical` — вне C1–C5 · `accepted-risk` — владелец принял риск

## Категории

`C1` тенанты · `C2` деньги/оплата · `C3` авторизация · `C4` падение hot-path · `C5` потеря данных

## Находки

| ID | Дата | Кат. | Файл:строка | Сценарий (кратко) | Тест | Статус | Коммит |
|----|------|------|-------------|-------------------|------|--------|--------|

## История аудитов

| Дата | Scope | Вердикт | Гейты (CI · smoke · Fly MCP) |
|------|-------|---------|------------------------------|
| 2026-09-29 | `0a3ac0db..dd072f3f` — 0 файлов кода (только docs/ops) | `CLEAN` | CI+Semgrep+CodeQL green на `0a3ac0db` ([36578912741](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578912741)) · smoke skip: код идентичен CI-прогону · Fly MCP skip: нет диффа hot-path |
