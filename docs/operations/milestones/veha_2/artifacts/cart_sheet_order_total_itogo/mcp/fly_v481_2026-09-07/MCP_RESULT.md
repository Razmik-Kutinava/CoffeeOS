# MCP Point A — CartSheet «Итого» (правка 5)

**App:** https://coffeeos.fly.dev  
**Fly:** **v481** · image `deployment-01M1X7DW5BC79WWJZPCXEWC5NB`  
**Tip:** `a9148d9b`  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Дата:** 2026-09-07  
**Сессия:** cursor-ide-browser MCP  

| # | Сценарий | Результат | Evidence |
|---|----------|-----------|----------|
| M1 | peek Итого + кнопка | **PASS** | `01_peek_itogo_and_plus_button.png` · DOM `shop-cart-order-total` = «Итого 5₽» · checkout `+5₽` |
| M2 | recalc 2+ | **PASS** | `02_peek_multi_itogo_recalc.png` · после `+` на линии Brazil: «Итого 7₽» / `+7₽` без reload |
| M3 | hidden visible total | **PASS** | `03_hidden_visible_total.png` · `shop-cart-hidden-total` = `7₽`, `sr-only=false`, display=block · chips ok · `+7₽` |
| M4 | expanded | **PASS** | `04_expanded_itogo.png` · mode=expanded · «Итого 7₽» + `+7₽` |
| M5 | regress gestures/CTA | **PASS** | swipe peek↔hidden↔expanded ok · CTA → `#/checkout` |

**Fly MCP:** **PASS**

### Notes
- Live pay / банк не трогали (out of scope).
- M6 thousands optional — skip (сумма 7₽ < 1000).
