# /review — PHASE 3 REVIEW

CoffeeOS. Читай: `spec-build-review` PHASE 3, `coffeeos-code-review`, `coffeeos-dev-gates`, `docs/operations/dev/ENTIRE.md`.

## Сделай
1. Task субагент **`bugbot`** (дифф ветки / uncommitted — по контексту).
2. Если трогали оплату / RLS / auth / callbacks / hot-path → ещё **`security-review`**.
3. **Entire (why-context):** на последнем GREEN/docs коммите задачи — `entire checkpoint explain <sha>` (WSL); сверить с `customer_tasks/*.md`, `todo.md`, при интеграции — `INTEGRATIONS.md` + секция. Зафиксировать в отчёте: учтены ли пункты spec / читал ли агент bridge.
4. Sanity: N+1, RLS, зона тестов уже после `/regress`.
5. Ops: шапки SESSION_STATE + CHANGELOG (месяц) + HANDOFF.
6. **Не** `git push` / `fly deploy` без явной просьбы владельца.

## Отчёт
Сделано | Не сделано + краткие findings bugbot.  
Hot-path: **Local** · **Fly MCP** (Point A или skip+почему).  
`Коммит: <хеш>` · `Субагент: bugbot` (± `security-review`)

## Обязательно в конце (копипаст)

Одной из строк (по факту):

`Next: push/deploy — только по апруву владельца`

или если ещё дыры в коде:

`Next: /sbr`

Если local PASS, но для заказчика нужен Fly:

`Next: Fly MCP Point A — по апруву владельца`
