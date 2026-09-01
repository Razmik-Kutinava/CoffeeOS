# Cursor Commands (CoffeeOS)

Slash-команды в чате Agent: введи `/` и выбери имя файла.

| Команда | Файл | Когда | Дальше (копипаст) |
|---------|------|-------|-------------------|
| `/start` | `start.md` | Старт; умный (не глотать всё). PHASE 0 только для нового ТЗ | `/spec` или `/sbr` |
| `/spec` | `spec.md` | SPEC + 2–7 файлов | `/sbr` |
| `/sbr` | `sbr.md` | RED→GREEN | `/regress` |
| `/regress` | `regress.md` | Тесты зоны **до** push/Fly | `/review` |
| `/review` | `review.md` | PHASE 3: local → 2 субагента → Entire → push/CI → стоп | `deploy — только по апруву` |
| `/trace-bug` | `trace-bug.md` | Сквозной аудит бага оплата/OTP/merge (до правок) | `/spec` или `/sbr` |
| `/ctx-trim` | `ctx-trim.md` | Архив ops, сжатие ISSUES, аудит rules, анализ токенов | `/start` |

Цепочка: `/start` → `/spec` → `/sbr` → `/regress` → `/review`  
**Периодика:** `/ctx-trim` — вручную или пт–вс (если `ctx_trim` >7 дней в HANDOFF)  
Диагностика интеграции: `/trace-bug` → `/spec` или `/sbr`

Карта: [`docs/integrations/INTEGRATIONS.md`](../../docs/integrations/INTEGRATIONS.md) (индекс) · секции [`docs/integrations/`](../../docs/integrations/) · Entire: [`docs/operations/dev/ENTIRE.md`](../../docs/operations/dev/ENTIRE.md)

Каждая команда **обязана** в конце напечатать строку `Next: /…` для копипаста.
