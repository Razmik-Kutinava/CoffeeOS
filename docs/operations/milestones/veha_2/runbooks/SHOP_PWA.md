# PWA витрины `/shop` — runbook

**Задача:** [B1_4_pwa_shop.md](../requirements/customer_tasks/B1_4_pwa_shop.md)  
**Статус:** код этапы 0–4 **2026-06-11** · Fly smoke `[ ]`

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
| Офлайн checkout queue | ✅ IndexedDB + `client_order_uuid` |

---

## Архитектура (целевая)

```
/shop (Svelte SPA)
  ├── manifest.webmanifest  → install, standalone
  ├── shop-sw.js            → precache shell + runtime cache catalog API
  └── firebase-messaging-sw.js → push (B1.1), scope /
```

**Вариант A (рекомендуемый для MVP):** один SW с модулями: precache + FCM importScripts.  
**Вариант B:** два SW — сложнее scope; только если FCM требует изоляции.

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
- При online — `POST /shop/api/orders` + идемпотентный `client_order_uuid`
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
5. Lighthouse + Fly smoke `bin/b14_pwa_fly_smoke.rb`

---

## Проверка

```bash
# Локально / Fly
# Chrome DevTools → Lighthouse → Progressive Web App
# Application → Service Workers → Offline checkbox

# После этапа 5
FLY_BIN=flyctl ruby bin/b14_pwa_fly_smoke.rb
```

---

## Связь

- [B1_1_order_status_progress.md](../requirements/customer_tasks/B1_1_order_status_progress.md) — push/WS  
- [OFFLINE_SYNC.md](OFFLINE_SYNC.md) — бариста offline В3  
- [ORDER_ENTRY_AUDIT.md](ORDER_ENTRY_AUDIT.md) — канал «shop PWA offline queue»
