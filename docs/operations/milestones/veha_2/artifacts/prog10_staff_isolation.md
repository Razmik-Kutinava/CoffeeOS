# Прогон 10 — Staff/RBAC изоляция по 9 точкам (блок 7)

**Дата:** 2026-06-02  
**Стенд:** `https://coffeeos.fly.dev`  
**Скрипт:** `bin/prog10_staff_rbac_isolation.rb`  
**JSON-отчёт:** `prog10_staff_isolation.json`  
**MCP UI:** [`prog10_staff_mcp_6pt.md`](prog10_staff_mcp_6pt.md) · [`prog10_staff_mcp_6pt.json`](prog10_staff_mcp_6pt.json) (актуально); срез 3 org: [`prog10_staff_mcp_3org.json`](prog10_staff_mcp_3org.json)

## Что проверено

- На каждой из 9 точек создан отдельный barista-staff (через UK `open_as_manager` -> manager/staff).
- Login barista проходит на своей точке.
- Изоляция заказов:
  - `GET /barista/orders/:own_id.json` -> `200`
  - `GET /barista/orders/:foreign_id.json` -> `404`
- Для `demo-prep-kitchen` barista-модуль ожидаемо недоступен (`302`), что подтверждает модульную изоляцию.

## Итог

- **9/9 PASS** по матрице изоляции.
- Перекрёстный доступ к заказам между точками не воспроизвёлся.
