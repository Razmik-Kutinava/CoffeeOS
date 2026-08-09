# /review — PHASE 3 REVIEW

CoffeeOS. Читай: `spec-build-review` PHASE 3, `coffeeos-code-review`, `coffeeos-dev-gates`.

## Сделай
1. Task субагент **`bugbot`** (дифф ветки / uncommitted — по контексту).
2. Если трогали оплату / RLS / auth / callbacks / hot-path → ещё **`security-review`**.
3. Sanity: N+1, RLS, зона тестов уже после `/regress`.
4. Ops: шапки SESSION_STATE + CHANGELOG (месяц) + HANDOFF.
5. **Не** `git push` / `fly deploy` без явной просьбы владельца.

## Отчёт
Сделано | Не сделано + краткие findings bugbot.  
`Коммит: <хеш>` · `Субагент: bugbot` (± `security-review`)

## Обязательно в конце (копипаст)

Одной из строк (по факту):

`Next: push/deploy — только по апруву владельца`

или если ещё дыры в коде:

`Next: /sbr`
