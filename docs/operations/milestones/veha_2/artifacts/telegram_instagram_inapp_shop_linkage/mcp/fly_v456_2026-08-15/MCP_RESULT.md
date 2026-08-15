# MCP Fly v456 — CBR #65 TG/IG In-App → `/shop` linkage

**Дата:** 2026-08-15  
**Fly:** **v456** · `deployment-01M02H0BQ0HYY6AFTRNWCS8RS5`  
**URL канон:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Инструмент:** cursor-ide-browser (Chrome Desktop)  
**Скрины:** [`mcp_v456_64_catalog.png`](mcp_v456_64_catalog.png) · [`mcp_v456_65_unknown_tenant.png`](mcp_v456_65_unknown_tenant.png)

## Результат: **Chrome PASS** · **TG/IG skip**

#64 пересечение (открытие) — PASS Chrome; не закрывать #64 целиком без телефона.

| Check | Result |
|-------|--------|
| 1. `/shop` Point A: 200, skeleton снят, меню Ленина, watchdog classic, meta Point A UUID | **PASS** |
| 2. `GET /shop/api/categories` same-origin, query = Point A UUID; meta = тот же UUID | **PASS** |
| 3a. `tenant_id=00000000-0000-0000-0000-000000000099` | **PASS** — не меню Ленина; `categories` **404** `{"error":"Точка не найдена"}`; шапка «Адрес не указан»; meta отсутствует |
| 3b. `/shop?tenant_id=` (пустой ключ) | **PASS** — не silent fallback; `categories` **422**; шапка «Адрес не указан»; `hasLenina: false` |
| 3c. Снова канон Point A | **PASS** — шапка Ленина, 10; meta Point A; каталог Черный |
| 4. Identity: нет «открой в Chrome»; нет auth по UA; OTP/PAN не писали | **PASS** |
| 5. Регресс: `#/product/3c5259e0-…` затем каталог жив | **PASS** (см. #66) |

**Заметка (не FAIL #65):** на unknown/blank в шторке «повторить» остались карточки гостевой сессии Point A. Каталог тела — не меню Ленина. Не чинили как баг #65.

**TG/IG устройства:** skip — не MCP.
