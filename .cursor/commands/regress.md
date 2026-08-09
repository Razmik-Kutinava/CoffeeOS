# /regress — регрессия зоны (до push / Fly)

CoffeeOS. Канон: `coffeeos-dev-gates.mdc` таблица зон + секция **«Проверка»** в todo.

## Когда
После GREEN / перед «готово к push». **Не** замена MCP на Fly — это локальные `bin/rails test …`.

## Сделай
1. Определи затронутую зону (shop / оплата / platform / barista / RLS / …).
2. Запусти команды из **«Проверка»** в todo; если пусто — из таблицы зон в `coffeeos-dev-gates`.
3. Длинный прогон → Task субагент **`shell`**.
4. Legacy shop ~24 fail — **не** гейт; гейт = выбранные команды зоны.
5. Запиши в отчёт: команда + runs/failures. FAIL → ISSUES или фикс (по намерению).
6. Hot-path витрина/оплата: напомни — **Fly MCP Point A** ещё нужен для «готово заказчику» (`Next` не врёт, что закрыто).
7. Обнови шапку SESSION_STATE (зона + PASS/FAIL). Коммит ops если менял файлы.

## Отчёт
Сделано | Не сделано.  
**Local:** …  
**Fly MCP:** skip — regress только local | …  
`Субагент: shell | нет`

## Обязательно в конце (копипаст)

Если PASS:

`Next: /review`

Если FAIL и чините здесь:

`Next: /sbr`
