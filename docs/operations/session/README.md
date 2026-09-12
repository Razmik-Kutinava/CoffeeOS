# docs/operations/session

Память «где остановились»: HANDOFF, SESSION_STATE, todo, COMPONENT_MAP.

> Для владельца и заказчика: что лежит в этой папке простыми словами. Агенту на `/start` — **только шапки** HANDOFF/SESSION + ISSUES 🔴 + живой `todo.md`. **`COMPONENT_MAP.md` не always.**

## Что внутри

| Файл | Роль |
|------|------|
| `HANDOFF.md` / `SESSION_STATE.md` | Шапка сессии |
| `todo.md` | Один живой чеклист текущей задачи (патч секции; не плодить `todo-*.md`) |
| `COMPONENT_MAP.md` | UI-карта зоны shop / active orders — читать/править **только** когда задача трогает зону; после Review — БЛОК 4 |
| `archive/` | Старые записи по месяцам — не читать без нужды |

## Зачем это нам

Быстрый контекст без раздувания токенов: карта компонентов — как `INTEGRATIONS.md`, точечно.
