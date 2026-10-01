# CRITICAL_LEDGER — журнал аудита критических ошибок

Канон: [`.cursor/rules/workflow/coffeeos-critical-audit.mdc`](../../../.cursor/rules/workflow/coffeeos-critical-audit.mdc) · команда `/crit-audit`.

> Новый чат: прочитать шапку + таблицу. Находки со статусом `fixed` / `rejected` / `accepted-risk` **не повторять**.

## Шапка

**last_audited_sha:** `6309066c` (TASK_SAFE-BOTTOM-MIN)  
**last_audit_date:** 2026-10-01  
**last_verdict:** `CLEAN` (CI pending до push)

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
| 2026-10-01 | `406b10e7..6309066c` — 10 файлов, только CSS/layout (`--shop-safe-bottom = max(8px, safe-area)` в `app.css` + `shopWebViewLayout.js`; 5 bottom-sheet на переменную; резерв Catalog/CategoryProducts/Product под CartSheet + safe-bottom — фикс находки bugbot, не C1–C5) · C1/C2/C3/C5 неприменимы · C4: кандидатов нет — числовое значение с `Math.max`/`Number()`, CSS fallback `0px`, `vite build` OK, Rails shop 420/0 | `CLEAN` | CI pending (до push) · smoke skip: полный `bin/rails test` зависает на Windows — `/regress` JS 616 (60 legacy) + Rails `test/integration/shop` 420/0 · Fly MCP: после deploy (запрещён до закрытия задачи) |
| 2026-10-01 | `44ec7814..406b10e7` — 1 файл (`ActiveOrdersAccordion.svelte`: декоративная стрелка `aoa__receipt-arrow` из константы `row.chevron` в кнопке чека) · C1/C2/C3/C5 неприменимы (UI-only, без пользовательских данных) · C4: кандидатов нет — SSR-рендер обоих состояний зелёный, `vite build` OK | `CLEAN` | CI pending (до push) · smoke skip: полный `bin/rails test` зависает на Windows — `/regress` JS 605 (60 legacy) + Rails 100/0 · Fly MCP: после deploy (запрещён до закрытия задачи) |
| 2026-10-01 | `0b54ac21..44ec7814` — 1 файл (`OrderStatusSheet.svelte`: режим только hidden/peek, `class:receipt-open` + `overflow-y: auto`, CSS `.expanded` удалён) · C1/C2/C3/C5 неприменимы (UI-only) · C4: кандидатов нет — `vite build` OK, браузер 390×844 PASS, Rails шторка 100/0 | `CLEAN` | CI pending (до push) · smoke skip: полный `bin/rails test` зависает на Windows — `/regress` JS 602 (60 legacy) + Rails 100/0 · Fly MCP: после deploy (запрещён до закрытия задачи) |
| 2026-10-01 | `0f06a868..0b54ac21` — 2 файла, только удаление (`ActiveOrdersAccordion.svelte`: кнопка `×`, проп `onDismiss`, CSS; `OrderStatusSheet.svelte`: проброс `onDismissOrder`, импорт `dismissOrder`) · C1/C2/C3/C5 неприменимы (UI-only, локальное скрытие без API) · C4: кандидатов нет — ссылок на `onDismiss`/`onDismissOrder` в `app/` не осталось, SSR-рендер зелёный | `CLEAN` | CI pending (до push) · smoke skip: полный `bin/rails test` зависает на Windows — `/regress` JS 597 (60 legacy) + Rails active_orders 13/0 + vite build · Fly MCP: после deploy (deploy запрещён до закрытия задачи) |
| 2026-09-30 | `dd072f3f..0f06a868` — 2 файла (`ActiveOrdersAccordion.svelte`, `activeOrdersAccordion.js`: вписывание чека в видимую область) · C1/C2/C3/C5 неприменимы (нет данных/денег/auth) · C4: кандидатов нет (SSR-рендер зелёный, effect-only DOM, null-guards, `ResizeObserver` guard) | `CLEAN` | CI pending (до push) · smoke skip: полный `bin/rails test` зависает на Windows (dev-gates) — зона JS 138/0 + Rails `active_orders_receipt` 4/0 · Fly MCP: после deploy (hot-path витрина, UI-only) |
| 2026-09-29 | `0a3ac0db..dd072f3f` — 0 файлов кода (только docs/ops) | `CLEAN` | CI+Semgrep+CodeQL green на `0a3ac0db` ([36578912741](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578912741)) · smoke skip: код идентичен CI-прогону · Fly MCP skip: нет диффа hot-path |
