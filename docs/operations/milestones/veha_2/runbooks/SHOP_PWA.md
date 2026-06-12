# PWA витрины `/shop` — runbook

**Задача:** [B1_4_pwa_shop.md](../requirements/customer_tasks/B1_4_pwa_shop.md)  
**Статус:** **OPS_PASS** 2026-06-12 · заказчик `[ ]`

---

## Зачем отдельный runbook

- **B1.4 PWA** — витрина гостя (`/shop`, Svelte).
- **OFFLINE_SYNC.md** — бариста POS, IndexedDB, **В3**; не смешивать.
- **B1.1 push** — FCM уже через отдельный SW; при PWA нужен план **одного или двух** service worker (см. ниже).

---

## Текущее состояние (baseline 2026-06-11)

| Что | Статус |
|-----|--------|
| HTTPS Fly | ✅ |
| `shop.html.erb` meta apple-mobile | ✅ частично |
| `manifest.json` подключён | ✅ `/shop/manifest.webmanifest` |
| SW кэш app shell | ✅ `/shop/service-worker.js` |
| `firebase-messaging-sw.js` | ✅ только FCM (отдельный SW) |
| Офлайн каталог | ✅ SW + localStorage |
| Офлайн add в корзину | ✅ IndexedDB `cart_queue` + optimistic localStorage |
| Офлайн checkout queue | ✅ IndexedDB + `client_order_uuid` в БД |
| Два SW (PWA + FCM) | ✅ работает · **долг:** слить в один (вариант A) |

---

## Архитектура (целевая)

```
/shop (Svelte SPA)
  ├── manifest.webmanifest  → install, standalone
  ├── shop-sw.js            → precache shell + runtime cache catalog API
  └── firebase-messaging-sw.js → push (B1.1), scope /
```

**Вариант A (рекомендуемый, долг):** один SW с модулями: precache + FCM importScripts.  
**Вариант B (сейчас):** два SW — работает, не блокер OPS_PASS; минус — два файла/versioning.

### Офлайн add в корзину

- Очередь `cart_queue` в IndexedDB (`shopOfflineCart.js`)
- Оптимистичное обновление `coffeeos_shop_cart_v1` в localStorage
- При `online` — `flushCartQueue` → `POST /shop/api/cart/add`

---

## Политика кэша (из ТЗ заказчика)

### Можно кэшировать

- Vite bundles (`/vite/assets/*`)
- Статика: иконки, шрифты, `icon-*.png`
- Shell `/shop` HTML
- **Публичный** каталог: `GET /shop/api/categories`, `GET /shop/api/products` — с TTL короткий (напр. 5–15 мин), ключ с `tenant_id`

### Нельзя кэшировать

- `POST` checkout, OTP, payment
- Ответы с персональными данными (email verify session)
- `push_token`, cookies сессии
- Динамические цены как «вечный» кэш без revalidate

### Офлайн checkout

- Тело заказа в **IndexedDB** (не Cache API)
- При online — `POST /shop/api/orders` + идемпотентный `client_order_uuid` (unique в `orders.client_order_uuid`)
- UI: «Заказ сохранён, отправим при появлении сети»

---

## Manifest

| Поле | CoffeeOS |
|------|----------|
| `name` | CoffeeOS |
| `short_name` | CoffeeOS |
| `start_url` | `/shop?tenant_id=<default или из meta>` |
| `scope` | `/shop` |
| `display` | `standalone` |
| `theme_color` | `#ff8c42` |
| `background_color` | `#1a1a1a` |
| `icons` | 192, 512, maskable |

**iOS:** `apple-mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, `apple-touch-icon` 180×180.

---

## Этапы реализации (синхрон с B1.4)

1. Manifest + icons + link в layout  
2. SW precache + register  
3. Runtime cache catalog + offline UI  
4. IndexedDB checkout queue + sync  
5. Formal acceptance (полный прогон)

---

## Проверка

**Полный прогон приёмки** (smoke + audit + скрины/LCP + finalize):

```bash
export BASE="${BASE:-https://coffeeos.fly.dev}"
export B14_TENANT_ID="${B14_TENANT_ID:-2fdee1ac-4674-41ee-b89e-87b45643f789}"

bash bin/b14_run_acceptance.sh
# или одной командой:
ruby bin/b14_pwa_acceptance_fly.rb
```

По шагам:

```bash
ruby bin/b14_pwa_fly_smoke.rb              # 1 — HTTP smoke
ruby bin/b14_pwa_programmatic_audit.rb     # 2 — PWA checklist 100%
node bin/b14_pwa_browser_shots.mjs         # 3 — скрины + LCP → tmp/b14_lcp.json
ruby bin/b14_finalize_acceptance.rb        # 4 — b14_pwa_acceptance_*.json OPS_PASS
```

Только smoke (без скринов/LCP): первые две команды + finalize **не** дадут свежий LCP.

Ручная проверка: Chrome DevTools → Application → Service Workers → Offline.

---

## Связь

- [B1_1_order_status_progress.md](../requirements/customer_tasks/B1_1_order_status_progress.md) — push/WS  
- [OFFLINE_SYNC.md](OFFLINE_SYNC.md) — бариста offline В3  
- [ORDER_ENTRY_AUDIT.md](ORDER_ENTRY_AUDIT.md) — канал «shop PWA offline queue»
