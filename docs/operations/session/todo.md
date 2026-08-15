# todo — #68 UX / Performance мобильной витрины в Telegram WebView

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 3 CI green | [run 31878722151](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31878722151) | deploy — только апрув |

**CBR:** #68  
**ТЗ:** [`customer_tasks/UX и Performance мобильной витрины CoffeeOS внутри Telegram WebView.md`](../milestones/veha_2/requirements/customer_tasks/UX%20и%20Performance%20мобильной%20витрины%20CoffeeOS%20внутри%20Telegram%20WebView.md)  
**Артефакты:** [`artifacts/mobile_storefront_telegram_webview_ux_perf/`](../milestones/veha_2/artifacts/mobile_storefront_telegram_webview_ux_perf/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 5. Опирается на #66 runtime (`shopWebView.js`, кэш по tenant) и #67 UI (`shopWebViewLayout.js`). Не переписывать #64–#67. #67 deploy/MCP — отдельно, не блокер local RED/GREEN.

## Цель (1 предложение)

В Telegram WebView каталог быстро показывает skeleton или stale-кэш, картинки не прыгают и не блокируют старт, retry/offline понятны и без двойных запросов, кэш не путает `tenant_id` и не стирает корзину.

## Acceptance (DoD)

1. Cold start без кэша: `PageSkeleton`, не пустой экран и не вечный loading.
2. Reopen с кэшем: сразу stale-контент, затем фоновый `loadCatalog` (SWR); API остаётся source of truth.
3. Кэш ключ `coffeeos_shop_catalog_v1:<tenant_id>`; URL/query tenant (#65) побеждает кэш другой точки.
4. Картинки каталога: `loading="lazy"` + существующий aspect-ratio (нет CLS); `onerror` → placeholder. Hero товара не lazy.
5. Нет нового image/CDN API: один `image_url`; не грузить below-fold до попадания в viewport.
6. Retry без reload страницы; повторный клик пока inflight → тот же запрос; живое меню не сменяем skeleton.
7. Offline: существующий `ShopPwaBanner` + каталог не падает; online → refetch. Не второй overlay.
8. UI различает сеть / HTTP 4xx–5xx / пустой каталог; 4xx/5xx без бесконечного auto-retry.
9. Background refresh / polling error не уничтожает уже показанное меню; корзина (`cartSheetStore`) не сбрасывается.
10. Storage SecurityError/quota не валит приложение (#66 try/catch). Контракт в `shop-api.md` § WebView UX/perf.
11. #66/#67 (runtime, viewport/safe-area/keyboard) не регрессируют. Bot / payments / БД / Prisma — вне scope.
12. Ручной Telegram + Fly MCP Point A — после апрува deploy; не блокер local GREEN.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED
- [x] GREEN
- [x] REVIEW / Fly MCP Point A / Telegram устройство
  - REVIEW PHASE 3 **local `[x]`** · CI **`[x]`** [31878722151](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31878722151) · Fly MCP `[ ]` · TG устройство `[ ]`

## Файлы (ожидаемо)

- `app/frontend/lib/stores/catalog.js` — SWR: сразу cache, потом revalidate; inflight уже есть — не дублировать; TTL/invalidation без вечного stale
- `app/frontend/routes/Catalog.svelte` — skeleton только без кэша; retry без `loading=true` поверх меню; kind сеть vs HTTP vs empty; online → refetch
- `app/frontend/components/CategorySection.svelte` — `loading="lazy"` (CLS `aspect-[4/3]` и onerror уже есть)
- `app/frontend/lib/shopNetwork.js` — тестируемый `catalogErrorKind` / reuse `isOfflineError` + `err.httpStatus`; не новый баннер
- `docs/integrations/shop-api.md` — § Embedded browser: WebView UX/perf (#68)
- `test/javascript/shop_telegram_webview_ux_perf_test.mjs` — **новый**: SWR, inflight coalesce, error kind, tenant cache key, budget (skeleton iff no cache)

### Blast-radius (+3)

- `app/frontend/routes/CategoryProducts.svelte` — *почему: тот же `loadCatalog` / `loading=true`; картинки без lazy/onerror*
- `test/javascript/shop_catalog_load_test.mjs` — *почему: 500 без кэша, cache-on-fail, tenant isolation должны остаться зелёными после SWR*
- `app/frontend/lib/api.js` — *почему: `httpStatus` уже есть; классификацию брать отсюда, **не** переписывать fetch/tenant*

## Не ломать

- #67 `shopWebViewLayout.js` / `--shop-vvh` / CartSheet px / keyboard / safe-area — не трогать «заодно»
- CartSheet канон одной шторки + `cartSheetStore` (peek/repeat/checkout) — retry/SWR каталога не reset корзины
- #66 `shopWebView.js`: detect ≠ auth, storage fallback, ключ кэша; #65 query `tenant_id` > meta
- `handleCatalogScroll` (window scroll → peek/hidden) и boot-watchdog #64

## Проверка

- `node --test test/javascript/shop_telegram_webview_ux_perf_test.mjs test/javascript/shop_catalog_load_test.mjs test/javascript/shop_telegram_webview_test.mjs test/javascript/shop_telegram_webview_ui_test.mjs`
- `bundle exec ruby -Itest test/integration/shop/shop_telegram_webview_test.rb test/integration/shop/shop_boot_skeleton_test.rb`

Fly MCP Point A + Telegram на телефоне — после апрува deploy. #67 deploy — не этот шаг.

## Риски / заметки

- Node-тесты импортируют **JS**, не Svelte: хелперы (`shouldShowCatalogSkeleton`, `catalogErrorKind`, SWR/inflight) в `catalog.js` / `shopNetwork.js`. Не монтировать `Catalog.svelte`.
- `PageSkeleton.svelte` / `shopLocalStorage.js` / `shopWebView.js` runtime — не в списке правок, пока GREEN не докажет дыру.
- Hero `Product.svelte` = LCP → **не** `loading="lazy"`. Thumbs корзины (`CartSheet`) не раздувать (#67 файл уже большой).
- API один `image_url` без srcset — не выдумывать thumbnail endpoint.
- Глобальный offline banner уже есть — не второй `fixed` слой.
- Не тащить Mini App SDK / Bot API / CORS / desktop layout / gem оплаты.
