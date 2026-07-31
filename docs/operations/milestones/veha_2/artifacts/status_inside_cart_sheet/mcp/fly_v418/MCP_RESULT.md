# MCP Fly — Status inside cart sheet v418

**Deploy:** Fly **v418** · image `deployment-01KYWD6MY6TFC80D9Y1181EDJN`  
**Commit:** `876b5432`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Сессия:** Aram `Профиль › 2bc3…4c` · `CART_SHEET_BUILD=prog36` · 14 active orders

## Критерий заказчика

> «вписать в шторку, а не поверх её … слой сверху»

| Проверка | Факт | Итог |
|---|---|---|
| Status DOM внутри cart | `shop-cart-sheet.contains(shop-order-status-sheet)` = true | **PASS** |
| parent | `parentTid=shop-cart-sheet` | **PASS** |
| embedded | `data-status-embedded=true` | **PASS** |
| CSS не overlay | `position=relative`, `zIndex=auto` (не fixed/60) | **PASS** |
| Cart fixed layer | cart `position=fixed` z50 — единственный sheet-overlay | **PASS** |
| Build marker | `data-cart-sheet-build=prog36` | **PASS** |
| Expanded всё ещё внутри | mode=expanded, receipts=1, `stillInside=true` | **PASS** |

## CDP (канон доказательства)

```json
{
  "build": "prog36",
  "insideCart": true,
  "embeddedAttr": "true",
  "statusCss": { "position": "relative", "zIndex": "auto" },
  "siblings": [
    { "tid": "shop-cart-sheet", "position": "fixed", "z": "50" },
    { "tid": "shop-order-status-sheet", "parentTid": "shop-cart-sheet", "position": "relative", "z": "auto" }
  ],
  "pass": true
}
```

## Скрин

- `01_catalog_with_session_fly_v418.png` — сессия Aram на v418 (DOM-доказательство — CDP выше)

**Overall:** **PASS**
