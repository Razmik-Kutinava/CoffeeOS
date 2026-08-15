# MCP Fly v456 — CBR #68 UX/perf витрины (Chrome Point A)

**Дата:** 2026-08-15  
**Fly:** **v456** · `deployment-01M02H0BQ0HYY6AFTRNWCS8RS5`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Скрины:** [`mcp_v456_68_product_hero.png`](mcp_v456_68_product_hero.png) · [`mcp_v456_68_offline.png`](mcp_v456_68_offline.png) · [`mcp_v456_67_header_iphone.png`](mcp_v456_67_header_iphone.png)

## Fly MCP: **PASS** (web Chrome) · **Telegram In-App skip**

| # | Что видел | Result |
|---|-----------|--------|
| 1 | Меню Point A, не вечный loading | **PASS** |
| 2 | Cold: HTML 200, затем каталог | **PASS** |
| 3 | Warm reopen после #65 — меню той же точки | **PASS** |
| 4 | Чужой UUID / пустой `tenant_id` — не меню Ленина | **PASS** (#65) |
| 5 | Скролл: карточки с aspect; прыжка LCP не видел | **PASS** |
| 6 | «Нет фото» на карточках без image; карточка кликабельна | **PASS** |
| 7 | Hero товара Бразилия на месте, без lazy-дыры | **PASS** |
| 8 | Offline: **один** баннер «Нет сети — меню и корзина из кэша…»; меню не исчезло | **PASS** |
| 9 | Online: баннер снят, не вечный loading | **PASS** |
| 10 | Ошибка без кэша чужой точки: «Ошибка сервера» / «Точка не найдена» | **PASS** (не Point A happy-path retry) |
| 11 | Фон/poll: меню осталось | **PASS** |
| 12 | Корзина `+5₽` жива через offline→online | **PASS** |
| 13 | Шапка+шторка #67 на месте | **PASS** |

Polling `/shop/api/categories` + `orders/active` + `frequent_products` ~каждые 8 с — канон шум, не взрыв.

**Telegram устройство:** skip — не этот MCP.
