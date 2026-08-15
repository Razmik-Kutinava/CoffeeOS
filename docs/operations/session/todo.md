# todo — #67 адаптация Mobile UI /shop под Telegram WebView

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 3 local review | push → CI | CI green → стоп · deploy апрув |

**CBR:** #67

**CBR:** #67  
**ТЗ:** [`customer_tasks/Адаптация Mobile UI витрины CoffeeOS под Telegram WebView.md`](../milestones/veha_2/requirements/customer_tasks/Адаптация%20Mobile%20UI%20витрины%20CoffeeOS%20под%20Telegram%20WebView.md)  
**Артефакты:** [`artifacts/mobile_storefront_telegram_webview_ui/`](../milestones/veha_2/artifacts/mobile_storefront_telegram_webview_ui/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 4. Опирается на #66 runtime (`shopWebView.js`, `--shop-vvh`). Задача 5 (UX/perf) — не этот шаг. #66 deploy/MCP — отдельно, не блокер local RED/GREEN.

## Цель (1 предложение)

В Telegram WebView каталог, sticky-шапка, CartSheet (peek/expanded) и CTA живут в **visual viewport** + safe-area: ничего не прячется под chrome Telegram / клавиатуру, внутренний скролл шторки не залипает, обычный мобильный браузер не ломается.

## Acceptance (DoD)

1. Высота layout от `visualViewport` / `--shop-vvh`, не от физического `100vh` экрана.
2. Sticky header (каталог / категория) в доступной зоне WebView (верхний safe-area).
3. CartSheet peek/expanded целиком в visual viewport; CTA видна; одна шторка, без второго `fixed`.
4. Overflow внутри шторки, если контент выше доступной высоты; page scroll каталога не «залипает».
5. Нижний safe-area у cart/CTA; верхний — у Header.
6. Клавиатура сжимает доступную высоту (input + CTA видимы); закрытие без пустого хвоста и без сброса mode/state корзины.
7. Resize/orientation пересчитывает viewport + sheet без сломанного overlay.
8. Контракт в `shop-api.md` § Embedded browser (WebView UI); identity/tenant/API #65/#66 не трогаем.
9. Chrome/Safari mobile и #64/#65/#66 runtime не регрессируют. Bot / payments / Prisma — вне scope.
10. Подзадача 17 (устройство Telegram) — после deploy #66; не блокер local GREEN.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED
- [x] GREEN
- [x] REVIEW / Fly MCP Point A / Telegram устройство
  - REVIEW PHASE 3 **local `[x]`** · CI `[ ]` · Fly MCP `[ ]` · TG устройство `[ ]`

## Файлы (ожидаемо)

- `app/frontend/lib/shopWebViewLayout.js` — **новый**: px от `--shop-vvh`, keyboard open/close (visualViewport height/offsetTop), safe-area CSS vars, max-height sheet; без auth/UA
- `app/frontend/styles/app.css` — html/body: `--shop-vvh`, overflow, `env(safe-area-inset-*)`; не считать layout от голого `100vh`
- `app/frontend/components/CartSheet.svelte` — высота/bottom/CTA в px visual viewport (не `${vh}vh` экрана); внутренний scroll; **не** раздувать файл — логика в layout.js
- `app/frontend/components/Header.svelte` — верхний safe-area / Telegram chrome (подзадача 9)
- `app/frontend/routes/Catalog.svelte` — нижний padding каталога от высоты шторки/`--shop-vvh`, полный скролл до конца (подзадача 13)
- `test/javascript/shop_telegram_webview_ui_test.mjs` — **новый**: viewport, resize, keyboard, safe-area, sheet-in-vvh, без потери state
- `docs/integrations/shop-api.md` — § Embedded browser: WebView UI (#67); индекс INTEGRATIONS уже указывает сюда

### Blast-radius (+2)

- `app/frontend/routes/CategoryProducts.svelte` — *почему: sticky header + `min-height: 100vh` на категории, тот же WebView chrome*
- `app/frontend/App.svelte` — *почему: `installShopWebViewLayout()` рядом с `installShopWebViewCompat()` (#66), одна точка boot*
- `test/integration/shop/b113_s2a_cart_sheet_acceptance_test.rb` — *почему: CI assertion CART_SHEET_BOTTOM_REM → `--shop-safe-bottom`*

## Не ломать

- CartSheet канон одной шторки: peek / «повторить» / checkout pay-stack / CTA товара — секции, не второй `fixed`
- `handleCatalogScroll` (window scroll → peek/hidden) — не заменить page-scroll на lock, который залипает каталог
- #66 `shopWebView.js`: detect ≠ auth, storage fallback, `--shop-vvh` setter, SPA stay-in-webview
- #65 query `tenant_id` > meta; Chrome/Safari mobile вне Telegram

## Проверка

- `node --test test/javascript/shop_telegram_webview_ui_test.mjs test/javascript/shop_telegram_webview_test.mjs`
- `bundle exec ruby -Itest test/integration/shop/shop_telegram_webview_test.rb test/integration/shop/shop_boot_skeleton_test.rb`

Fly MCP Point A + Telegram на телефоне — после апрува deploy (подзадача 17). Задача 5 (perf) — не этот шаг.

## Риски / заметки

- `CartSheet.svelte` уже >700 строк — GREEN только подставляет px из layout.js, иначе сплит + апрув.
- `SHEET_VH` проценты оставляем; множитель = visualViewport height, не `window.innerHeight`.
- Checkout `CHECKOUT_PAY_STACK_VH = 92` на коротком WebView обязан **капиться** в доступную высоту (иначе CTA под клавиатурой).
- Нет visualViewport → fallback `innerHeight`, UI не падает (контракт заказчика).
- Keyboard нельзя честно закрыть в node:тест — мок `visualViewport.height` вверх/вниз; устройство — подзадача 17.
- Не тащить Mini App SDK / Bot API / глобальный CORS / desktop layout.
