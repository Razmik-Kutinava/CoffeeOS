# Прогон 10 — MCP Staff (6 точек, блок 7 продолжение)

**Стенд:** `https://coffeeos.fly.dev`  
**JSON:** [`prog10_staff_mcp_6pt.json`](prog10_staff_mcp_6pt.json)  
**Предыдущий срез:** [`prog10_staff_mcp_3org.json`](prog10_staff_mcp_3org.json) (первые 3 org)

## Итог

| Канал | Охват |
|-------|--------|
| **curl** | 9/9 — без изменений |
| **MCP STF-01/02** | **6/9** sales_point (по 2 на org) |
| **MCP STF-03** | **6/9** — создание barista в manager/staff |
| **MCP STF-04** | 6 новых `mcp-stf03-*-06021250@prog10.local` → `/barista` на своей точке |
| **Не в браузере** | `demo-prep`, `alpha-p3`, `beta-p3` |

**Блок 7 ещё не закрыт** в чеклисте: ждём апрув; 3 точки остаются только curl.

## STF-03 — как создавали

| Точка | Способ |
|-------|--------|
| **demo-b** | UI: `puppeteer_fill` + клик `#role_barista` + submit |
| demo-a, alpha-p1/p2, beta-p1/p2 | Форма `/manager/staff` через **POST в сессии браузера** (UK → open_as_manager → POST, не CLI curl) |

Пароль новых: `demo123456`.

## Точки STF-01/02 (batch 2, +3 к первым 3)

- `demo-b` — Demo Coffee Point B  
- `alpha-p2` — Prog10 Alpha Point 2  
- `beta-p2` — Prog10 Beta Point 2  

## Следующий шаг

Апрув → блок **8** (ENT-02, ENT-07, ENT-08).
