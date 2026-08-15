# MCP Fly v456 — CBR #64 Shop Telegram/Instagram in-app open

**Дата:** 2026-08-15  
**Fly:** **v456** · `deployment-01M02H0BQ0HYY6AFTRNWCS8RS5`  
**Machine:** web `9080d40db67238` ams · checks passing  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Инструмент:** cursor-ide-browser (Chrome Desktop Point A)  
**Скрин:** [`mcp_v456_64_catalog.png`](mcp_v456_64_catalog.png)

## Результат: **Chrome PASS** · **TG/IG skip**

Не закрывать CBR `[x]`: нужен тап в Telegram/Instagram на телефоне владельца + «ок» заказчика.

| Check | Result |
|-------|--------|
| A1 HTML 200, `tenant_id` в адресе | **PASS** |
| A2 Skeleton «Загрузка меню…» исчез | **PASS** (`skeletonExists: false`) |
| A3 Шапка **Москва, ул. Ленина, 10** | **PASS** |
| A4 Каталог: категории + товары + цены | **PASS** (Черный, Фильтр-кофе, Холодные, Сезоные) |
| A5 `GET /shop/api/categories?tenant_id=2fdee1ac-…` 200 JSON | **PASS** same-origin |
| A6 `id="shop-boot-watchdog"` без `type=module`; Vite `type=module` | **PASS** |
| B7 CartSheet / peek | **PASS** |
| B8 Секция «повторить» | **PASS** (есть; не чинили) |
| B9 Нет redirect «открой в Chrome»; нет UA-веток | **PASS** |
| C10 Catalog «Повторить» | **SKIP** happy-path — кнопки нет (ожидаемо) |
| C11 Watchdog не виден на Point A (порог 12 с) | **PASS** |

**TG/IG устройства:** skip — MCP не имитирует In-App Browser.

### Harvest

```
meta shop-tenant-id = 2fdee1ac-4674-41ee-b89e-87b45643f789
GET /shop/api/categories?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 → 200
watchdog: id="shop-boot-watchdog">  (classic)
```
