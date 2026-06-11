# Задача: PWA витрины (CoffeeOS)

**ID:** B1.4 · **Источник:** заказчик, ТЗ PWA e-commerce  
**Статус:** ТЗ + baseline **2026-06-11** · реализация `[ ]` · заказчик `[ ]` · **приоритет: высокий** (после B2.2 или параллельно по решению)

**Связано:** [B1.1](B1_1_order_status_progress.md) (WS + push в браузере) · [B1.7](B1_7_checkout_order_screen.md) (checkout) · [B2.1](B2_1_barista_order_board.md) (табло — не PWA)

---

## CoffeeOS — scope (читаем перед текстом заказчика)

| Тема | Решение |
|------|---------|
| **Канал** | Витрина `/shop` — Svelte SPA (Vite), layout `shop.html.erb` |
| **Не делаем** | Нативные iOS/Android приложения; изменение бизнес-логики оплаты/доставки/Т-Банк |
| **HTTPS** | ✅ Fly `coffeeos.fly.dev` |
| **Push сейчас** | FCM через `firebase-messaging-sw.js` — **только уведомления**, не PWA-кэш |
| **PWA сейчас** | Заготовки Rails `app/views/pwa/*` — **не подключены** (`routes.rb` закомментированы, manifest не в `shop.html.erb`) |
| **Офлайн бариста** | [`OFFLINE_SYNC.md`](../../runbooks/OFFLINE_SYNC.md) — **В3**, не эта задача |
| **Кэш персональных данных** | **Запрещено** по ТЗ: токены, auth, цены «в открытом виде» — только shell + публичный каталог по политике кэша |
| **start_url** | `/shop?tenant_id=<uuid>` (режим B; см. B1.7 / QR) |
| **Иконки / theme** | Бренд CoffeeOS: bg `#1a1a1a`, accent `#ff8c42` (как витрина) |

### Что уже есть в коде (baseline)

| Компонент | Файл | Сейчас |
|-----------|------|--------|
| Layout витрины | `app/views/layouts/shop.html.erb` | `apple-mobile-web-app-capable`, viewport, Firebase meta |
| Manifest (заготовка) | `app/views/pwa/manifest.json.erb` | `display: standalone`, **не подключён**, theme `red`, один `icon.png` |
| SW Rails PWA | `app/views/pwa/service-worker.js` | **Весь код закомментирован** |
| SW FCM | `app/views/shop/firebase_sw/show.js.erb` | Только push, route `/firebase-messaging-sw.js` |
| Регистрация push | `app/frontend/lib/firebasePush.js` | `navigator.serviceWorker.register("/firebase-messaging-sw.js")` |
| Иконка | `public/icon.svg` | Нет PNG 192×512 для manifest |
| Роуты PWA | `config/routes.rb` | `# get "manifest"` — закомментировано |

**Артефакт baseline:** [`b14_stage0_baseline_2026-06-11.json`](../../artifacts/demo-feedback/b14_stage0_baseline_2026-06-11.json)  
**Runbook:** [`SHOP_PWA.md`](../../runbooks/SHOP_PWA.md)

---

## Прогресс по этапам

```
[ ] 0 — baseline + маппинг (этот док + stage0 json)
[ ] 1 — manifest + иконки + meta iOS + подключение в shop layout
[ ] 2 — Service Worker: shell (JS/CSS/HTML), installability
[ ] 3 — Офлайн каталог/корзина (кэш API по политике, UI «нет сети»)
[ ] 4 — Офлайн checkout: очередь IndexedDB + sync при online
[ ] 5 — Install prompt UX + Lighthouse PWA 100% + Fly smoke
```

---

## Мастер-чеклист

### Этап 0 — baseline `[ ]` 2026-06-11

- [x] ТЗ заказчика зафиксировано в этом файле
- [x] Baseline кода и пробелов — `b14_stage0_baseline_2026-06-11.json`
- [x] Runbook `SHOP_PWA.md`
- [ ] Скрин «до»: витрина в браузере без install / Lighthouse PWA audit

### Этап 1 — manifest + install shell `[ ]`

- [ ] `manifest.json` для `/shop`: `name`, `short_name`, `icons` 192+512, `start_url`, `scope`, `display: standalone`, `theme_color`, `background_color`
- [ ] `link rel="manifest"` + `apple-touch-icon` в `shop.html.erb`
- [ ] Роут manifest (Rails `pwa#manifest` или статический под `/shop`)
- [ ] PNG иконки в `public/` (192, 512, maskable)

### Этап 2 — Service Worker (app shell) `[ ]`

- [ ] Регистрация SW для витрины (отдельно или объединение с FCM — см. runbook)
- [ ] Precache: Vite assets, fonts, shell HTML
- [ ] Стратегия обновления SW (skipWaiting / clients.claim, очистка старого кэша)

### Этап 3 — офлайн просмотр `[ ]`

- [ ] Кэш последнего каталога / категорий (без токенов сессии в Cache API)
- [ ] Fallback UI при offline на `/shop` routes
- [ ] Повторный визит: LCP ≤ 2.5 с на 4G из кэша (критерий заказчика)

### Этап 4 — офлайн checkout queue `[ ]`

- [ ] Попытка заказа offline → сохранение в IndexedDB + понятное уведомление
- [ ] При восстановлении сети — автоматическая отправка очереди
- [ ] Идемпотентность / защита от дублей (client id)

### Этап 5 — приёмка `[ ]`

- [ ] Lighthouse PWA: 100% чек-лист (manifest, SW, HTTPS, icons, viewport)
- [ ] Chrome Android: «Добавить на главный экран» → standalone
- [ ] Safari iOS: meta + icon, корректный status bar
- [ ] Артефакт `b14_pwa_acceptance_*.json` + скрины `screenshots/b14_pwa_*/`
- [ ] Скрипт Fly smoke `bin/b14_pwa_fly_smoke.rb` *(создать на этапе 5)*

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
| 1 | Lighthouse PWA | Google Lighthouse вкладка PWA | 100% чек-лист (manifest, SW, HTTPS, icons, viewport) | `[ ]` |
| 2 | LCP повторный визит | Mobile 4G, из кэша | ≤ 2.5 с | `[ ]` |
| 3 | Install | Иконка на главном экране | Запуск в `display: standalone` | `[ ]` |
| 4 | Офлайн каталог | Airplane mode после визита online | Каталог/корзина из кэша | `[ ]` |
| 5 | Офлайн checkout | Нет сети на оплате | Очередь + sync при online | `[ ]` |
| 6 | iOS Safari | iPhone | Meta + icon + standalone-поведение в рамках Safari | `[ ]` |
| 7 | Без утечки PII | Аудит кэша | Нет токенов/OTP в Cache/IDB | `[ ]` |

---

## MVP vs позже

| Функция | MVP B1.4 | Позже |
|---------|----------|-------|
| Manifest + standalone | `[ ]` | — |
| SW app shell | `[ ]` | — |
| Офлайн каталог/корзина | `[ ]` | — |
| Офлайн очередь заказа | `[ ]` | — |
| Install banner / beforeinstallprompt | `[ ]` | A/B тексты |
| Push в установленной PWA | частично (FCM B1.1) | унификация с одним SW |
| Background Sync API | `[ ]` optional | если браузер поддерживает |
| Per-tenant manifest icons | — | white-label |

---

## Код (целевые файлы)

| Компонент | Файл |
|-----------|------|
| Layout | `app/views/layouts/shop.html.erb` |
| Manifest | `app/views/pwa/manifest.json.erb` или `public/shop-manifest.json` |
| SW PWA | `app/views/pwa/service-worker.js` или `app/frontend/shop-sw.js` |
| SW FCM | `app/views/shop/firebase_sw/show.js.erb` |
| Роуты | `config/routes.rb` |
| Офлайн очередь | `app/frontend/lib/shopOfflineQueue.js` *(создать)* |
| Регистрация SW | `app/frontend/entry` / `application` bootstrap |
| Fly smoke | `bin/b14_pwa_fly_smoke.rb` *(этап 5)* |

---

## Приёмка

| Измеритель | Мы | Заказчик |
|------------|-----|----------|
| Lighthouse PWA 100% | `[ ]` | `[ ]` |
| Install standalone | `[ ]` | `[ ]` |
| Офлайн каталог | `[ ]` | `[ ]` |
| Офлайн checkout sync | `[ ]` | `[ ]` |
| iOS корректность | `[ ]` | `[ ]` |

**Приёмка заказчика:** дата ______ · комментарий ______

### Артефакты (план)

- `artifacts/demo-feedback/b14_stage0_baseline_2026-06-11.json`
- `artifacts/demo-feedback/b14_pwa_acceptance_*.json`
- `artifacts/demo-feedback/screenshots/b14_pwa_*/`
