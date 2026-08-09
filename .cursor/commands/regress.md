# /regress — регрессия зоны (до push / Fly)

CoffeeOS. Канон: `coffeeos-dev-gates.mdc` таблица зон.

## Когда
После GREEN / перед «готово к push». **Не** замена MCP на Fly — это локальные `bin/rails test …`.

## Сделай
1. Определи затронутую зону (shop / оплата / platform / barista / RLS / …).
2. Запусти **команду(ы)** из таблицы зон в `coffeeos-dev-gates`.
3. Длинный прогон → Task субагент **`shell`**.
4. Запиши в отчёт: команда + runs/failures. FAIL → ISSUES или фикс (по намерению).
5. Обнови шапку SESSION_STATE (зона + PASS/FAIL). Коммит ops если менял файлы.

## Отчёт
Сделано | Не сделано.  
`Субагент: shell | нет`

## Обязательно в конце (копипаст)

Если PASS:

`Next: /review`

Если FAIL и чините здесь:

`Next: /sbr`
