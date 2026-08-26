# Bridge: Shop API (`/shop/api/*`)

PWA / mobile витрина. Tenant: `@shop_tenant` из `tenant_id` query или subdomain. RLS: `Current.tenant_id` в base controller.

**Оплата (детали T-Bank):** [`tbank.md`](tbank.md) · **Real-time:** [`pwa-realtime.md`](pwa-realtime.md) · **OTP/merge:** [`sms-auth.md`](sms-auth.md)

---

## Config & tenant

| Method | Path | Service / controller | Notes |
|--------|------|----------------------|-------|
| GET | `config` | `ConfigController#show` | `operating_hours` (B1.11), tenant meta |
| GET | `tenants` | `TenantsController#index` | выбор точки (B1.14) |

**Edge:** `OperatingHoursGuard` — `orders#create` и все `payments/*` возвращают 422 если точка закрыта.

---

## Session & auth

| Method | Path | Service | Keys / response |
|--------|------|---------|-----------------|
| POST | `session/refresh` | `Shop::SessionRefresh` | `{ refresh_token }` → новый token, profile; 401 ротация fail |
| DELETE | `session` | `CustomerSession.clear!` | logout ЛК (#69); `{ ok, logged_out }`; optional `{ refresh_token }` → deactivate `mobile_sessions` |
| POST | `session/reconnect` | `Shop::GuestOrderReconnect` | `order_id`, `reconnect_token` → bind guest order |
| POST | `email_otp/send\|verify` | `Shop::EmailOtp` | checkout email verify |
| GET | `email_otp/status` | — | cooldown |
| POST | `phone_otp/init_callcheck` · `send_sms` · `verify_sms` | `Shop::PhoneOtp` | Callcheck → SMS fallback |
| GET | `phone_otp/check_status` | session `check_id` | 401 → auth |
| POST/GET | `phone_otp/send\|verify\|status` | legacy Profile SMS | flash_call **rejected** |

**Mapping:** `mobile_sessions` (refresh_token, expires_at 90d) · cookie `_coffeeos_session` 90d · LS `shop_refresh_token`.

**Tests:** `session_refresh_test.rb` · `phone_otp_test.rb` · `email_otp_*_test.rb`

---

## Profile & cards

| Method | Path | Service | Keys |
|--------|------|---------|------|
| GET/PATCH | `profile` | `ProfileController` | `mobile_customers.id` |
| POST | `profile/link_email` | `CustomerProfileMerger#link_email!` | merge donor→survivor |
| POST | `profile/link_phone` | `CustomerProfileMerger#link_phone!` | перенос cards FK |
| GET | `user/cards` | `UserCardsController` | `?email=` fallback; filter expired exp |

**Edge:** без session/email → `{ cards: [] }` (не 401). Слабая session в repeat-flow → пустые cards (ISSUES one-click).

---

## Catalog & cart

| Method | Path | Notes |
|--------|------|-------|
| GET | `categories`, `products`, `products/:id` | catalog + tenant settings |
| GET | `frequent_products` | Quick Repeat: `has_active_order`, `frequent_items`, `categories` |
| POST/PATCH/DELETE | `cart/*` | `Shop::CartService`; offline queue в SW |
| GET/POST/DELETE | `favorites/*` | избранное |

**Tests:** `frequent_products_test.rb` · `quick_repeat_*_test.rb`

---

## Orders

| Method | Path | Service | Notes |
|--------|------|---------|-------|
| POST | `orders` | `Shop::OrderCreator` | create + optional payment init |
| GET | `orders/:id` | — | `reconnect_token` в JSON для Cable |
| GET | `orders/active` | — | sticky sheet; receipt lines (#36) |
| GET | `orders/history` | — | `{ id, order_number, title, status, total, created_at, items_count }`; `?page=&per_page=` |
| POST | `orders/:id/abandon` | `PaymentFailureJournal` | pending_payment только; clear pending session |
| POST | `orders/:id/cancel` | `GuestOrderCancellationService` | refund via TbankAdapter (#40) |
| POST | `orders/:id/finalize` | `TbankPaymentSync` | post-return sync; clear cart if accepted |
| GET | `orders/:id/wallet_pass` | Apple Wallet | `.pkpass` blob |

**Edge:** stale `accepted` в active → блок оплаты / скрытые повторы (#35, #42). `abandon` ≠ `cancel`.

**Tests:** `active_orders_test.rb` · `active_orders_receipt_test.rb` · `orders_controller_test.rb`

---

## Payments (shop → T-Bank)

| Method | Path | Service | T-Bank |
|--------|------|---------|--------|
| GET | `payments/card_config` | `PaymentCryptoConfig` | RSA pub для CardData |
| POST | `payments/new_card` | `NewCardPaymentService` | Init + FinishAuthorize + save_card |
| POST | `payments/one_click` | `OneClickPaymentService` | Init → Charge (RebillId) |
| POST | `payments/sbp/init` | `SbpPaymentInitiator` | Init + GetQr → payment_url |
| POST | `payments/sbp/charge` | `SbpAutopayChargeService` | ChargeQr + AccountToken |
| POST | `payments/widget_init` | `WidgetPaymentInitiator` | Init DATA Widget |
| GET | `payments/status/:order_id` | `TbankPaymentSync` | GetState; Confirm if AUTHORIZED |

Полная матрица и decision tree: [`tbank.md`](tbank.md) · gap: [`gap-matrix-pwa-payments.md`](gap-matrix-pwa-payments.md)

**Tests:** `qa_section_2_3_*` · `sbp_*_test.rb` · `payment_widget_init_test.rb` · `shop_usercards_*`

---

## Push

| Method | Path | Service |
|--------|------|---------|
| POST | `push/register` | `PushRegistrationService` | `push_token`, FCM |

Требует авторизованного customer (email). Детали: [`notify-loyalty.md`](notify-loyalty.md)

---

## Promo & debug

| Method | Path |
|--------|------|
| POST | `promo_codes/apply` |
| GET | `debug` | non-production only |

---

## Проверка (batch preflight)

```bash
bin/rails test test/integration/shop/api/session_refresh_test.rb
bin/rails test test/integration/shop/api/profile_merge_test.rb
bin/rails test test/integration/shop/api/frequent_products_test.rb
bin/rails test test/integration/shop/api/active_orders_test.rb
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb
bin/rails test test/integration/shop/api/sbp_payment_init_test.rb
bin/rails test test/integration/shop/api/sbp_autopay_charge_test.rb
bin/rails test test/integration/shop/api/payment_widget_init_test.rb
bin/rails test test/integration/shop/shop_usercards_phase1_persist_test.rb
```

Приёмка: Fly MCP **Point A** `2fdee1ac-4674-41ee-b89e-87b45643f789`.

---

## Embedded browser (Telegram / Instagram In-App)

Связка: пользователь открывает публичную витрину **ссылкой** `GET /shop?tenant_id=<UUID>` во встроенном браузере Telegram или Instagram. Это **не** Mini App и **не** авторизация.

| Внешнее | Наше |
|---------|------|
| ссылка `/shop?tenant_id=` | `@shop_tenant` / catalog API `tenant_id` |
| Telegram/Instagram user_id, username, phone | **не маппятся** на `user_id` |
| User-Agent / факт WebView | **не** механизм auth |

### Целостность tenant_id (#65)

Цепочка: внешняя ссылка → `GET /shop?tenant_id=` (meta `shop-tenant-id`) → FE `withTenantQuery` → `GET /shop/api/categories?tenant_id=`.

- Query `tenant_id` **побеждает** meta и silent fallbacks.
- Ключ `tenant_id` **присутствует, но пуст** → ошибка связки (нет meta / API 422), **не** подмена другой точкой.
- Неизвестный UUID → нет meta / API 404.
- Без ключа `tenant_id` — прежние fallbacks (header / ENV / single tenant) для обычного Chrome.

Каталог: `GET /shop/api/categories?tenant_id=<UUID>` (same-origin). CORS «на всякий случай» не добавляем. Forced redirect в Chrome/Safari — не основной фикс.

Bootstrap: HTML содержит `shop-boot-skeleton`; единственный Vite entry — `type="module"`. Если module не исполнился, classic `shop-boot-watchdog` снимает вечную «Загрузка меню…». UA-ветки — не канон фикса.

### Telegram WebView runtime (#66)

Связка: Telegram In-App Browser (WebView) → `GET /shop?tenant_id=` (PWA/Svelte) → same-origin `GET /shop/api/*`. Это **не** Bot API и **не** Mini App.

| Внешнее | Наше |
|---------|------|
| In-App Browser как runtime | `app/frontend/lib/shopWebView.js` |
| cookies `_coffeeos_session` | `fetch(..., { credentials: "same-origin" })` |
| localStorage / sessionStorage | try/catch + memory fallback; catalog cache `coffeeos_shop_catalog_v1:<tenant_id>` |
| visualViewport / keyboard | `--shop-vvh` + `viewport-fit=cover` |
| WebView UI (#67) | `app/frontend/lib/shopWebViewLayout.js` · CartSheet/Header в px visual viewport |

- Origin витрины = origin API → CORS не расширяем.
- CSP: `connect-src 'self'` (+ банк). `telegram.org` SDK не подключаем.
- Identity: WebView **не** подменяет `user_id`; `tenant_id` только по контракту #65 (query > meta; не client-only cache).
- Storage недоступен → меню через API; ошибка API → error/retry (#64), не бесконечный loading.
- SPA hash остаётся в WebView; внешние `t.me` не считаются внутренними маршрутами.
- Повторное открытие: URL `tenant_id` побеждает кэш другой точки.
- Фактические ограничения WebView — в `artifacts/mobile_storefront_telegram_webview/diag/`, не копия доки Telegram.

### Telegram WebView UI (#67)

Связка: Telegram In-App Browser / WebView → CoffeeOS Mobile UI. Поверх runtime #66, **без** новых backend endpoints.

| Внешнее | Наше |
|---------|------|
| visual viewport (не `window.innerHeight`) | `--shop-vvh` + `shopWebViewLayout.js` |
| keyboard / resize | `--shop-keyboard-inset`; sheet px пересчёт; state peek/cart **не** сбрасывается |
| safe-area top/bottom | `--shop-safe-top` / `--shop-safe-bottom` → Header / CartSheet |
| bottom sheet / cart CTA | `sheetHeightPx` капит высоту в доступную область |

- Identity: UI viewport **не** меняет `tenant_id` / `user_id` (#65/#66).
- Нет visualViewport → fallback `innerHeight`, UI не падает.
- Page scroll каталога **не** lock-ается шторкой (`handleCatalogScroll`).
- Обычный мобильный Chrome/Safari без необходимости не меняем.
- Не auth: viewport state не заменяет серверную валидацию tenant/user.

### Telegram WebView UX / Performance (#68)

Связка: Telegram In-App Browser / WebView → CoffeeOS UX/perf каталога. Поверх #66/#67, **без** новых backend endpoints.

| Внешнее | Наше |
|---------|------|
| Mobile storefront в In-App Browser | `Catalog.svelte` + `PageSkeleton` / error / retry |
| `GET /shop/api/categories` | `loadCatalog()` · SWR cache `coffeeos_shop_catalog_v1:<tenant_id>` |
| Картинки `product.image_url` | lazy + aspect-ratio + onerror placeholder; без нового CDN/variant API |
| Сеть online/offline | `shopNetwork.js` + существующий `ShopPwaBanner` |

- Identity: задача **не** меняет mapping. Кэш изолирован по tenant; `tenant_id` не берётся только из cache (#65 query > meta).
- Cache — UX-ускорение, не source of truth и не auth credentials.
- Network error → retry (inflight coalesce); offline → баннер, не падение; online → refetch.
- HTTP 4xx/5xx → error state без бесконечного auto-retry.
- Background refresh error → оставить уже показанное меню.
- Storage error → network path, если доступен (#66 try/catch).
- Skeleton / error / retry живут в visual viewport #67 (не ломать `--shop-vvh` / safe-area / keyboard).

**#64** · тесты: `shop_boot_skeleton_test.rb` · `shop_catalog_load_test.mjs`  
**#65** · тесты: `shop_api_tenant_query_test.mjs` · `shop_tenant_linkage_test.rb` · categories `?tenant_id=`  
**#66** · тесты: `shop_telegram_webview_test.mjs` · `shop_telegram_webview_test.rb`  
**#67** · тесты: `shop_telegram_webview_ui_test.mjs` · `shop_telegram_webview_test.rb` (layout/UI contract)  
**#68** · тесты: `shop_telegram_webview_ux_perf_test.mjs` · `shop_catalog_load_test.mjs` (SWR / tenant cache)