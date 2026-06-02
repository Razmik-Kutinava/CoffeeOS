# Прогон 10 — MCP Staff/RBAC (9 точек, блок 7)

**Стенд:** `https://coffeeos.fly.dev`  
**Дата:** 2026-06-02  
**JSON:** [`prog10_staff_mcp_9pt.json`](prog10_staff_mcp_9pt.json)  
**curl baseline:** [`prog10_staff_isolation.json`](prog10_staff_isolation.json)

## Scope (STF)

В браузере проверено:
- **STF-01** `open_as_manager` → `/manager` (UK → карточка точки)
- **STF-02** `/manager/staff` — созданный barista виден в списке
- **STF-03** создание staff в UI: **barista staff ×9 точек**
- **STF-04** вход нового staff: ведёт на `/barista` на sales_point

## Особенность `demo-prep`

`demo-prep` относится к production kitchen и barista-модуль ожидаемо недоступен. При пробе `GET /barista` не возвращает панель barista (redirect/ответ не на `/barista`), что соответствует логике `prog10_staff_isolation.json`.

## Итог

| Блок | Канал | Результат |
|------|-------|-----------|
| 7 | curl | `prog10_staff_isolation.json`: PASS 9/9 |
| 7 | MCP UI | `prog10_staff_mcp_9pt.json`: STF-03 PASS **9/9** (create+in_list), STF-04 PASS на sales_point |

**Статус:** блок 7 готов к закрытию после твоего апрува перед блоком **8**.
