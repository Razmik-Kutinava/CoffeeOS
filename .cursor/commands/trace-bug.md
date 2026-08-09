# /trace-bug — сквозной аудит интеграции (hot-path)

CoffeeOS. Только для багов **оплата / Т-Банк / OTP / merge профиля / карты / СБП / SMS cascade**.  
Не замена `/sbr` — это диагностика **до** правок.

## Перед стартом

1. `@INTEGRATIONS.md` (индекс) → **один** файл из таблицы маршрутизации (не все секции).
2. Шапка `HANDOFF` + 🔴 `ISSUES` если баг уже заведён.
3. **Не** `@codebase` — узкий grep/read по цепочке из todo.

## Вход (заполни в чате или попроси пользователя)

- **Сценарий:** [название, напр. «регистрация + старые платежи не подтянулись»]
- **Сбой:** [что видит пользователь / лог / ErrorCode]
- **Сущности:** [PWA экран, API route, таблица, webhook]

## Обязательный анализ (вывод в чат)

### 1. Trace Flow
Client (PWA) → API route → middleware/session/tenant → service → DB → external API/webhook → sync обратно в PWA.

Покажи **где рвётся** (файл + гипотеза).

### 2. Identity & Auth Gap
- phone/email/customer_id совпадают между шагами?
- Был ли `CustomerProfileMerger` / duplicate `mobile_customers`?
- `CustomerKey` / `OrderId` / `PaymentId` mapping по `docs/integrations/tbank.md` (или индекс).

### 3. Event & Webhook Audit
- Дошёл ли webhook? Idempotency (`duplicate: true`)?
- Terminal status downgrade?
- Ошибки проглочены в rescue без лога?

### 4. Side Effects (Не ломать)
Что сломается при «быстром фиксе»: one-click, save_card, SBP autopay, merge, repeat order, Point A tenant.

### 5. Fix Strategy
Минимальный diff + тесты из секции «Проверка» в `docs/integrations/*.md` / `coffeeos-dev-gates`.

## Формат ответа (краткий Impact Assessment)

```
Affected: PWA | Backend | DB | Webhooks
Side effects: …
Mitigation: …
Files (2–7): …
Проверка: bin/rails test …
```

## После диагностики

- Если нужен SPEC → `Next: /spec`
- Если готов RED → `Next: /sbr`
- Read-only шаг → коммит не нужен

`Субагент: explore` — если цепочка неочевидна после 2–3 файлов.
