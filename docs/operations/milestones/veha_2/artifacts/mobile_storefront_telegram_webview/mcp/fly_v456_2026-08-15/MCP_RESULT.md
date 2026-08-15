# MCP Fly v456 — CBR #66 Telegram WebView runtime (Chrome Point A)

**Дата:** 2026-08-15  
**Fly:** **v456** · `deployment-01M02H0BQ0HYY6AFTRNWCS8RS5`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Скрины:** [`mcp_v456_64_catalog.png`](mcp_v456_64_catalog.png) · [`mcp_v456_66_product.png`](mcp_v456_66_product.png)

## Итог: **MCP #66 Chrome PASS** · **Telegram In-App skip**

MCP = Chrome на том же URL. Настоящий Telegram WebView — телефон владельца.

| # | Шаг | Result |
|---|-----|--------|
| 1 | Cold start: HTML+Svelte, не вечный skeleton, каталог Point A | **PASS** |
| 2 | `GET /shop/api/categories?tenant_id=2fdee1ac-…` same-origin 200; CORS preflight на fly.dev нет | **PASS** |
| 3 | CSP не валит витрину; `telegram.org` SDK не грузится | **PASS** (CSP без telegram.org; scripts пусто) |
| 4 | `/shop/api/*` несут Point A UUID; UA ≠ auth | **PASS** |
| 5 | Карточка `#/product/3c5259e0-f42f-4d47-953d-2ce82e335f8c` → назад `#/`; хост остаётся coffeeos.fly.dev | **PASS** |
| 6 | Cache `coffeeos_shop_catalog_v1:2fdee1ac-…` | **PASS** |
| 7 | Reopen канон URL после негатива #65 — меню той же точки | **PASS** |
| 8 | `viewport-fit=cover` в meta | **PASS** (chrome TG — skip) |
| 9 | Airplane catalog | **PASS** через #68 offline (баннер, не вечный loading) |
| 10 | Chrome без TG UA | **PASS** (= этот прогон) |

**Заметка:** есть также голый ключ `coffeeos_shop_catalog_v1` (14 авг). На unknown UUID меню Point A **не** всплыло — изоляция query работает.

CSP header (сокращённо): `default-src 'self'` · `connect-src 'self' wss:` + tinkoff/nspk · **нет** telegram.org.
