# todo — #66 полноценная работа /shop внутри Telegram WebView

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN local | REVIEW | Fly MCP / TG устройство после deploy апрув |

**CBR:** #66  
**ТЗ:** [`customer_tasks/Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser.md`](../milestones/veha_2/requirements/customer_tasks/Полноценная%20работа%20мобильной%20витрины%20CoffeeOS%20внутри%20Telegram%20In-App%20Browser.md)  
**Артефакты:** [`artifacts/mobile_storefront_telegram_webview/`](../milestones/veha_2/artifacts/mobile_storefront_telegram_webview/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 3. #64/#65 MCP не закрывать этим шагом. Задачи 4 (UI) и 5 (perf) — не этот шаг.

## Цель (1 предложение)

Витрина `/shop` в Telegram In-App Browser работает как обычный мобильный браузер: mount → API same-origin → tenant_id по контракту #65 → storage/cookies с fallback → SPA-навигация внутри WebView → viewport без перекрытия ключевого UI.

## Acceptance (DoD)

1. Compatibility-слой изолирован (`shopWebView.js`); UA **не** auth.
2. API `/shop/api/*` same-origin + `credentials: same-origin`; глобальный CORS не добавляем.
3. CSP не расширяем «под Telegram»; `connect-src 'self'` достаточен (origin = витрина).
4. localStorage/sessionStorage throw → fallback, приложение не падает.
5. Повторное открытие: `tenant_id` из URL, не чужой catalog cache.
6. Hash-навигация остаётся в WebView; не `window.open` внутренних `/shop` маршрутов.
7. `--shop-vvh` + `viewport-fit=cover`; визуальная полировка экранов — задача 4.
8. Обычный Chrome/Safari и #64/#65 не регрессируют. Bot/payments/auth — вне scope.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED
- [x] GREEN
- [ ] REVIEW / Fly MCP Point A / Telegram устройство
  - REVIEW `[ ]` · Fly MCP `[ ]` · TG устройство `[ ]`

## Файлы (ожидаемо)

- `app/frontend/lib/shopWebView.js` — isolated layer: detect (не auth), safe storage, viewport CSS var, SPA stay-in-webview, cold start/reopen tenant
- `app/frontend/App.svelte` — `installShopWebViewCompat()` на boot (рядом с `initTelegram`, без Mini App SDK)
- `app/frontend/lib/shopGuestSession.js` — `reconnectGuestOrder` без голого `sessionStorage` (throw → не падать)
- `app/frontend/lib/stores/catalog.js` — cache key с `tenant_id` (reopen без чужого меню) — *почему: storage fallback иначе отдаёт каталог другой точки*
- `app/views/layouts/shop.html.erb` — `viewport-fit=cover`; watchdog #64 не трогать
- `docs/integrations/shop-api.md` § Embedded browser — контракт WebView runtime (#66)
- `test/javascript/shop_telegram_webview_test.mjs` + `test/integration/shop/shop_telegram_webview_test.rb`

## Не ломать

- #64 boot watchdog / Catalog «Повторить» / storage throw → loadCatalog
- #65 query `tenant_id` > meta; blank key ≠ silent fallback
- CartSheet / peek / «повторить»
- Rails CSRF; без глобального CORS; Telegram Bot / payments / SMS

## Проверка

- `node --test test/javascript/shop_telegram_webview_test.mjs test/javascript/shop_api_tenant_query_test.mjs test/javascript/shop_catalog_load_test.mjs test/javascript/shop_local_storage_test.mjs`
- `bundle exec ruby -Itest test/integration/shop/shop_telegram_webview_test.rb test/integration/shop/shop_boot_skeleton_test.rb test/integration/shop/shop_tenant_linkage_test.rb`

Fly MCP Point A — после deploy (апрув). Telegram на телефоне — отдельно.

## Риски / заметки

- `initTelegram()` = Mini App `WebApp`; In-App Browser по ссылке ≠ Mini App. Не подключать telegram.org SDK «на всякий случай» (CSP).
- Instagram — зона #64/#65, не плодить IG-ветки.
- Viewport: только CSS-переменная и meta; не переписывать все `100vh` (это задача 4).
