# Cursor Commands (CoffeeOS)

Slash-команды в чате Agent: введи `/` и выбери имя файла.

| Команда | Файл | Когда | Дальше (копипаст) |
|---------|------|-------|-------------------|
| `/start` | `start.md` | Старт; умный (не глотать всё). PHASE 0 только для нового ТЗ | `/spec` или `/sbr` |
| `/spec` | `spec.md` | SPEC + 2–7 файлов | `/sbr` |
| `/sbr` | `sbr.md` | RED→GREEN | `/regress` |
| `/regress` | `regress.md` | Тесты зоны **до** push/Fly | `/review` |
| `/review` | `review.md` | bugbot ± security | push/deploy по апруву |

Цепочка: `/start` → `/spec` → `/sbr` → `/regress` → `/review`

Каждая команда **обязана** в конце напечатать строку `Next: /…` для копипаста.
