# /sbr — RED → GREEN по todo

CoffeeOS SBR BUILD. Читай: `spec-build-review`, `coffeeos-commit-ops`, `coffeeos-dev-gates`, `coffeeos-tests`.

## Сделай
1. Работай **только** по файлам из todo «Файлы (ожидаемо)» (+ зеркальные тесты; добор +1 путь в todo).
2. **RED:** падающий тест → коммит `test: … [RED]` (без CHANGELOG/HANDOFF).
3. **GREEN:** реализация → зелёные тесты задачи → коммит `feat: … [GREEN]`. Сразу `entire checkpoint explain HEAD` — не пустой. Пусто → `entire session attach` (`ENTIRE.md`), не «spec OK». Без commit why-context на Review стоп.
4. Длинный suite / регрессия зоны → Task **`shell`**; узкий один test-файл — можно сам.
5. Не `@codebase` зря. Не рой ce-*.
6. Если пользователь сказал только RED — стоп после RED с `Next: /sbr` (продолжить GREEN) или явным «дальше GREEN».

## Отчёт
Сделано | Не сделано + команды тестов + PASS/FAIL.  
`Коммит: <хеш>` · `Субагент: shell | explore | нет`

## Обязательно в конце (копипаст)

После успешного GREEN:

`Next: /regress`

Если только RED (ещё нужен GREEN):

`Next: /sbr`
