# Задача: PWA витрины (CoffeeOS)

**ID:** B1.4 · **Источник:** заказчик, ТЗ PWA e-commerce  
**Статус:** этапы **0–5** **OPS_PASS** 2026-06-12 · заказчик `[ ]` (после апрува)

**Связано:** [B1.1](B1_1_order_status_progress.md) (WS + push в браузере) · [B1.7](B1_7_checkout_order_screen.md) (checkout) · [B2.1](B2_1_barista_order_board.md) (табло — не PWA)

---

## CoffeeOS — scope (читаем перед текстом заказчика)

| Тема | Решение |
|------|---------|
| **Канал** | Витрина `/shop` — Svelte SPA (Vite), layout `shop.html.erb` |
| **Не делаем** | Нативные iOS/Android приложения; изменение бизнес-логики оплаты/доставки/Т-Банк |
| **HTTPS** | ✅ Fly `coffeeos.fly.dev` |
| **Push сейчас** | FCM через `firebase-messaging-sw.js` — **только уведомления**, не PWA-кэш |
| **PWA** | `/shop/manifest.webmanifest` + `/shop/service-worker.js` · FCM отдельно |
| **Офлайн бариста** | [`OFFLINE_SYNC.md`](../../runbooks/OFFLINE_SYNC.md) — **В3**, не эта задача |
| **Кэш персональных данных** | **Запрещено** по ТЗ: токены, auth, цены «в открытом виде» — только shell + публичный каталог по политике кэша |
| **start_url** | `/shop?tenant_id=<uuid>` (режим B; см. B1.7 / QR) |
| **Иконки / theme** | Бренд CoffeeOS: bg `#1a1a1a`, accent `#ff8c42` (как витрина) |

**Артефакты:** [`b14_pwa_acceptance_2026-06-12.json`](../../artifacts/demo-feedback/b14_pwa_acceptance_2026-06-12.json) · скрины [`b14_pwa_2026-06-11/`](../../artifacts/demo-feedback/screenshots/b14_pwa_2026-06-11/)  
**Runbook:** [`SHOP_PWA.md`](../../runbooks/SHOP_PWA.md)

---

## Прогресс по этапам

```
[x] 0 — baseline + маппинг (2026-06-11)
[x] 1 — manifest + иконки + meta iOS (2026-06-11)
[x] 2 — Service Worker: shell + register (2026-06-11)
[x] 3 — Офлайн каталог/корзина + баннер (2026-06-11)
[x] 4 — Офлайн checkout queue + client_order_uuid (2026-06-11)
[x] 5 — Fly smoke + PWA audit 100% + LCP + скрины (2026-06-12)
```

---

## Мастер-чеклист

### Этап 0 — baseline `[x]` 2026-06-11

- [x] ТЗ заказчика зафиксировано в этом файле
- [x] Baseline кода и пробелов — `b14_stage0_baseline_2026-06-11.json`
- [x] Runbook `SHOP_PWA.md`
- [x] Скрин «до» — baseline зафиксирован до деплоя; Lighthouse после Fly

### Этап 1 — manifest + install shell `[x]`

- [x] `manifest.json` — `/shop/manifest.webmanifest`
- [x] `link rel="manifest"` + `apple-touch-icon` в `shop.html.erb`
- [x] Роут `Shop::PwaController#manifest`
- [x] PNG `public/pwa/icon-192.png`, `icon-512.png`, `apple-touch-icon.png`

### Этап 2 — Service Worker (app shell) `[x]`

- [x] SW `/shop/service-worker.js` (scope `/shop/`), FCM отдельно
- [x] Precache shell + `/vite/*` stale-while-revalidate
- [x] `skipWaiting` + `clients.claim` + очистка старых кэшей
- [x] `shopPwa.js` — register + `beforeinstallprompt`

### Этап 3 — офлайн просмотр + add в корзину `[x]`

- [x] SW runtime cache `categories` / `products` / `cart` GET
- [x] localStorage fallback каталога и корзины
- [x] `shopOfflineCart.js` — очередь `POST /cart/add` офлайн + optimistic cart
- [x] `ShopPwaBanner` — баннер offline
- [x] LCP ≤ 2.5 с — замер `bin/b14_pwa_browser_shots.mjs` → `tmp/b14_lcp.json`

### Этап 4 — офлайн checkout queue `[x]`

- [x] `shopOfflineQueue.js` — IndexedDB + уведомление в checkout
- [x] `flushOrderQueue` при `online` + в `App.svelte`
- [x] `client_order_uuid` + `OrderCreator` idempotency (`orders.client_order_uuid` unique)

### Этап 5 — приёмка `[x]` 2026-06-12

- [x] **Полный прогон:** `bash bin/b14_run_acceptance.sh` (= smoke → audit → browser_shots → finalize)
- [x] PWA audit 100% — `bin/b14_pwa_programmatic_audit.rb` (LH 13+ без категории pwa)
- [x] Fly smoke PASS — `bin/b14_pwa_fly_smoke.rb`
- [x] LCP + скрины — `bin/b14_pwa_browser_shots.mjs` (не только smoke+finalize)
- [x] Скрины: `lighthouse_pwa_audit`, `standalone_home_screen`, `install_prompt_android`, `offline_catalog`, `offline_checkout_queued`
- [ ] **Долг:** слить PWA SW + FCM в один worker (сейчас два — не блокер)
- [ ] iOS add-to-home скрин — после апрува на устройстве
- [x] Артефакт `b14_pwa_acceptance_2026-06-12.json` — **OPS_PASS**

---

## Проблема (заказчик)

Мобильная веб-версия сайта имеет высокий показатель отказов (Bounce Rate) при нестабильном интернет-соединении и низкую скорость повторного посещения. Пользователи вынуждены скачивать нативное приложение из магазинов для получения быстрого доступа, что создает дополнительный барьер для совершения первой покупки и увеличивает стоимость привлечения клиента (CAC).

---

## Решение (текст заказчика — без сокращений)

### Продуктовые требования

- Пользователь получает возможность добавить иконку сайта на главный экран мобильного устройства.
- Сайт открывается в полноэкранном режиме (без адресной строки и элементов управления браузера), имитируя опыт нативного приложения.
- Основные сценарии (просмотр каталога, добавление товара в корзину, просмотр ранее загруженных страниц) остаются доступными при временном отсутствии интернет-соединения.

### Технологические требования

- Реализация Service Worker для кэширования статических ресурсов (HTML, CSS, JS, изображения) и избранных API-ответов.
- Наличие файла `manifest.json` с корректными параметрами: `name`, `short_name`, `icons` (размеры 192x192 и 512x512), `start_url`, `display: standalone`, `theme_color`, `background_color`.
- Сайт должен работать исключительно по протоколу HTTPS.
- Совместимость с актуальными версиями мобильных браузеров (Chrome для Android, Safari для iOS).

### User Story

**Как** мобильный пользователь,  
**я хочу** установить сайт как приложение на главный экран телефона и просматривать каталог товаров без активного интернет-соединения,  
**чтобы** быстро совершать покупки и не зависеть от качества сети.

### Use Case (алгоритм взаимодействия)

1. Пользователь открывает сайт в мобильном браузере.
2. Пользователь выбирает опцию «Добавить на главный экран» (или браузер предлагает баннер установки PWA).
3. Пользователь запускает сайт с иконки на главном экране.
4. Интерфейс открывается в режиме `standalone` (без интерфейса браузера).
5. Пользователь теряет соединение с интернетом.
6. Пользователь переходит в раздел каталога или корзины.
7. Система отображает ранее закэшированные данные из Service Worker.
8. При попытке оформить заказ в офлайн-режиме система сохраняет данные в локальное хранилище и отображает уведомление о том, что заказ будет отправлен при восстановлении связи.
9. При восстановлении соединения данные автоматически синхронизируются с сервером.

### Corner cases

- **Попытка оформления заказа при отсутствии сети:** данные сохраняются в `IndexedDB` или `localStorage`, пользователю показывается понятное уведомление о статусе.
- **Обновление версии Service Worker:** старый кэш корректно очищается, пользователь получает актуальные версии файлов при следующем визите.
- **Поведение на iOS (Safari):** корректное отображение иконок и статус-бара с учётом специфичных мета-тегов Apple (`apple-mobile-web-app-capable`, `apple-touch-icon`).

### Ограничения — чего не делаем

- Не разрабатываем нативные мобильные приложения (iOS/Android).
- Не изменяем бизнес-логику оформления заказа, расчёты стоимости доставки и интеграции с платежными шлюзами.
- Не кэшируем персональные данные пользователей, токены авторизации и динамические цены в открытом виде.

*(Примечание заказчика: детальные техспеки по структуре кэша и макеты иконок — Confluence, ссылка TBD.)*

---

## Критерии приёмки MVP

| # | Критерий | Измеритель | Цель | Формально |
|---|----------|------------|------|-----------|
| 1 | Lighthouse PWA | programmatic audit (LH 13+) | 100% | `[x]` Fly |
| 2 | LCP повторный визит | Mobile 4G, из кэша | ≤ 2.5 с | `[x]` **183 ms** |
| 3 | Install | Иконка на главном экране | `display: standalone` | `[x]` manifest + скрин |
| 4 | Офлайн каталог | offline после online | Каталог из кэша | `[x]` скрин |
| 5 | Офлайн checkout | Нет сети на оплате | Очередь + sync | `[x]` скрин |
| 6 | iOS Safari | iPhone | Meta + icon | `[x]` audit · скрин устройства `[ ]` |
| 7 | Без утечки PII | Аудит кэша | Нет токенов/OTP | `[x]` |

---

## Долги (не сейчас — после апрува / отдельные задачи)

| Что | Почему отложено |
|-----|-----------------|
| Слить PWA SW + `firebase-messaging-sw.js` в один | Работает; риск регрессии push |
| Background Sync API | Опционально сверх ТЗ |
| A/B тексты install-баннера | Опционально |
| Per-tenant manifest icons (white-label) | Опционально |
| iOS add-to-home скрин | Физическое устройство |
| Перепрогон `b14_run_acceptance.sh` шаг 3 | Playwright в WSL тормозит; артефакты OPS_PASS есть |
| Приёмка заказчика B1.4 | Ждём внутренний апрув |
| Домен `*.shop…` + DNS + Fly certs | Инфра прод, см. CHECKLIST §витрина |

**Витрина (не B1.4):** промокод убран из корзины и checkout (BR); API `/promo_codes` на бэке остаётся для будущего.

---

## MVP vs позже

| Функция | MVP B1.4 | Позже |
|---------|----------|-------|
| Manifest + standalone | `[x]` | — |
| SW app shell | `[x]` | — |
| Офлайн каталог/корзина + add офлайн | `[x]` | — |
| Офлайн очередь заказа | `[x]` | — |
| `client_order_uuid` в БД | `[x]` | — |
| Install banner / beforeinstallprompt | `[x]` | A/B тексты |
| Push в установленной PWA | частично (FCM B1.1) | унификация с одним SW |
| Background Sync API | долг | если браузер поддерживает |
| Per-tenant manifest icons | долг | white-label |

---

## Код (целевые файлы)

| Компонент | Файл |
|-----------|------|
| Layout | `app/views/layouts/shop.html.erb` |
| Manifest | `app/views/shop/pwa/manifest.json.erb`, `Shop::PwaController` |
| SW PWA | `app/views/shop/pwa/service_worker.js.erb` |
| SW FCM | `app/views/shop/firebase_sw/show.js.erb` |
| Роуты | `config/routes.rb` — `/shop/manifest.webmanifest`, `/shop/service-worker.js` |
| PWA bootstrap | `app/frontend/lib/shopPwa.js`, `shopNetwork.js` |
| Офлайн очередь заказа | `app/frontend/lib/shopOfflineQueue.js` |
| Офлайн add в корзину | `app/frontend/lib/shopOfflineCart.js`, `shopCartAdd.js` |
| Приёмка Fly | `bin/b14_run_acceptance.sh`, `b14_pwa_browser_shots.mjs` |
| UI | `app/frontend/components/ShopPwaBanner.svelte` |
| Idempotency | `Shop::OrderCreator#find_client_order_duplicate!` |
| Иконки | `public/pwa/*.png`, `bin/generate_pwa_icons.ps1` |
| Fly smoke | `bin/b14_pwa_fly_smoke.rb` |

---

## Приёмка

| Измеритель | Мы | Заказчик |
|------------|-----|----------|
| Lighthouse PWA 100% | `[x]` OPS | `[ ]` |
| Install standalone | `[x]` | `[ ]` |
| Офлайн каталог | `[x]` | `[ ]` |
| Офлайн checkout sync | `[x]` | `[ ]` |
| iOS корректность | `[x]` meta/audit | `[ ]` |

**Приёмка заказчика:** после апрува · дата ______

### Артефакты

- `b14_pwa_acceptance_2026-06-12.json` — **OPS_PASS**
- `b14_pwa_fly_smoke_2026-06-12.json`
- `screenshots/b14_pwa_2026-06-11/` — 5 скринов
