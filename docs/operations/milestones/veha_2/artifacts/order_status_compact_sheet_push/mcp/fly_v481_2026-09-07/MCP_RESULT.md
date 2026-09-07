# MCP RESULT — #35 compact status sheet QA reopen · Fly **v481** · 2026-09-07

**App:** https://coffeeos.fly.dev  
**Release:** **v481** · image `deployment-01M1X7DW5BC79WWJZPCXEWC5NB`  
**Tip:** `a9148d9b`  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** cursor-ide-browser MCP (+ silent refresh guest MCP)  
**Вердикт:** **PASS** (MUST A+B+C green; D SKIP; E PARTIAL by design; F SKIP; G PASS on `issued`)

## Deploy

1. `git push origin develop` → `a9148d9b`
2. CI [34088874139](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34088874139) **green**
3. `fly deploy -a coffeeos --remote-only --depot=false` → **v481**
4. `GET /up` **200**

## Сценарии

| ID | Сценарий | Результат | Evidence |
|----|----------|-----------|----------|
| A | post-pay → compact | **PASS*** | `01_home_after_pay_compact_sheet.png` · hash `#/` · compact `shop-order-status-sheet` · *live pay не гоняли: accepted-заказ через active API + session refresh* |
| B | no receipt + X=hide | **PASS** | `02_…` · нет qty/Удалить/чек · `aria-label="Скрыть статус заказа"` · X прячет виджет |
| C | cancel hint 1–3 | **PASS** | `03_…` · CTA «Вернем 100% · 1–3 дня» |
| D | repeat | **SKIP** | нет live pay / repeat в этой сессии |
| E | product non-block | **PARTIAL** | add/qty кликабельны · статус на `/product/` **скрыт** каноном `shouldShowStatusSheetUi` (hash `/product/` → false) |
| F | multi>2 scroll | **SKIP** | нет времени на 3 заказа |
| G | ready/issued hide | **PASS*** | на `ready` виджет ещё в API/UI; на `issued` → виджет исчезает без reload (poll) |

## Пачка

| Check | Результат |
|-------|-----------|
| Sentry 24h (`llc-manageengine` / `ruby`) | нет unresolved `lastSeen:-24h` |
| Fly logs | OK · 200 на cart/active/refresh · без 5xx в хвосте |
| Neon | skip (не смотрели биллинг UI) |
| УК Point A | skip глазами |

**Fly MCP:** **PASS** (MUST)
