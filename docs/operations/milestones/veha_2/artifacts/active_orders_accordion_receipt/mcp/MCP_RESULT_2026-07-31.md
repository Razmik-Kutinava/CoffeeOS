# MCP Fly #36 — 2026-07-31

**Deploy:** Fly **v415** · image `deployment-01KYW6BGFN2073Z1XYB1STSPTB`  
**Commit:** `cdab89ee` (push develop)  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789

## Сверка с каноном заказчика (`screenshots/01–02`)

| Критерий | Эталон | Fly MCP | Вердикт |
|---|---|---|---|
| 1 заказ expanded + текстовый чек | 01 | receipt: item + Subtotal/Discount/Total; `buttonsInside=0`; `max-height:350px` | **PASS** |
| 2+ заказов, один `v` / другой `>` | 02 | click 2nd chevron → `expandedCount=1`; first collapsed, second expanded | **PASS** |
| Статус-лайн 4 шага | 01/02 | labels Принят/Оплачен/Готовится/Готов | **PASS** |
| Чек без интерактива | ТЗ | no button/a/input inside receipt | **PASS** |
| Sheet layering | #35 | `z-index:60`, sheet visible | **PASS** |
| Stub CTA «кнопка с текстом» | mock | `.aoa__stub` видны | PASS (placeholder) |

## Доказательства

- `01_single_expanded_fly_v415.png` — первый заказ expanded + чек
- `02_multi_one_expanded_fly_v415.png` — верх свёрнут, второй expanded

## DOM / CDP

- rows: 14 · receipt maxHeight `350px` overflowY `auto`
- one-open: after toggle second → first `aria-expanded=false`, second `true`, `receiptCount=1`
- receipt sample: item lines + Subtotal/Discount/Total Amount; no «повторить»

## Остаток / notes

- «Потеряно соединение…» при многих Cable-подписках (как #35) — не блокер UI чека
- Demo: много «зависших» active orders → длинная шторка
- Stub CTA copy — PRACTICES V2-#36-STATUS-CTA-COPY
