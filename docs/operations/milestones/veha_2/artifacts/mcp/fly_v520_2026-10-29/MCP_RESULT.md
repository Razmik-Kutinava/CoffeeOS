# Fly v520 — 🚀 2 + 🚀 3 (шаги 6–9 очереди Push + SMS) · 2026-10-29

**Итог: FAIL по одному критерию, регрессий поставки нет.** Деплой прошёл (v520, web 1/1). Всё, что поставлено в шагах 6–9, на проде и локально работает: классы окружения, вход в push на экране заказа, «закрыл диалог» ≠ «запретил», диагностика по жесту, панель при заблокированном хранилище. Регрессия 🚀 1 (корзина при смене точки, beacon, read-only API без cookie) — зелёная. **FAIL:** в сценарии TASK_113 (заблокированное хранилище браузера) в Console 2× `Uncaught (in promise) SecurityError`. Источник — не код поставки, а старый `codeblackPendingOrder.js` (CODE:BLACK, `d4f43691`), который читает `localStorage` без защиты. По коду в таком браузере перестанет работать и переход в банк по СБП (не воспроизводилось — «Оплатить» не нажимали). → ISSUES 🔴, решение владельца.

**Коммит:** `0bf32436` (код шагов 6–9 — `727f3429..0bf32436`) · CI [40830710186](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40830710186) + Semgrep [40830710189](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40830710189) + CodeQL [40830710170](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40830710170) green на `0bf32436` · deploy [40833617768](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40833617768) (07:09:26–07:10:58 UTC) · release **v520**, машины на v520 с 07:10:41 UTC, образ `deployment-01M637WK02YT4VTH01DHV7WMW5` · миграций нет (`git diff --stat 727f3429..HEAD -- db/` пусто) · web 1/1 health passing
**В поставке относительно v518:** TASK_90 Патч 2 (закрытый без выбора диалог → «Уведомления не включены»), TASK_108 (диагностика push только по флагу, жест 7 нажатий / 3 с на «Заказ»), TASK_113 (push-код устойчив к недоступному хранилищу), TASK_109 (классы окружения A–E, push-CTA только где push возможен, единый вход в push на экране заказа). Только фронт.
**До деплоя:** HEAD = `origin/develop` = `0bf32436` · CI/Semgrep/CodeQL green · `db/` без изменений · `WALLET_FORCE_UNAVAILABLE` **не** выставлялся (отдельный апрув) · 👤 ручной тест iPhone с видимой диагностикой (условие 🚀 2) — **пропущен по решению владельца** (2026-10-29).
**Деплой с повторами (Fly API, не наш код):** [40831815561](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40831815561) — образ собран, но Fly 504 «failed to set release status to 'running'» → v519 остался `pending` (машины на v518); [40832416300](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40832416300) и [40833118763](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40833118763) — Fly API 503 «failed to get organization» (локально `fly releases` тоже 503, статус-страница — operational); после восстановления API — [40833617768](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40833617768) success → v520. v519 — осиротевший `pending`, на машинах не был.

## Как проверяли

Chrome DevTools MCP (`chrome-devtools-mcp`, добавлен в `~/.cursor/mcp.json` по решению владельца), каждый сценарий — отдельный изолированный профиль (чистый гость). Прод `coffeeos.fly.dev`, Point A `2fdee1ac-…`, точка B — кухня `d47165db-…` (как в v518). Без OTP, без PAN, «Оплатить» не нажималась, профиль Арама не трогали. На каждом сценарии — скрин, Console, Network.

**Что на проде, что локально.** Активный заказ на проде без оплаты не получить (`accepted` только после T-Bank, онлайн-наличные запрещены), поэтому сценарии экрана заказа и панели активных заказов — **локально, не prod** (`bin/rails server -p 3001` + `bin/vite dev`, тот же код `0bf32436`, Demo Point A `8c7f5bc7-…`, тестовые заказы `ae0ed429-…` #202610-0001 `preparing` и `9ba9bdb4-…` #202610-0002 `accepted`, гость привязан через `reconnect_token`). На проде — классы окружения (по телу beacon TASK_112 — это и есть входы классификации), жест TASK_108 (заголовок «Заказ» рисуется и на «Заказ не найден»), заблокированное хранилище, регрессия 🚀 1, наличие кода поставки в бандле.

**Подмены (init script) — честно:**
- Разрешение уведомлений: в изолированном профиле Chrome настоящее разрешение = `denied` → сценарии L4 и L8 (`denied`) — **на настоящем `denied`**; `dismissed` (L3, L9) — подмена `Notification.permission = 'default'` + `requestPermission → 'default'` (вызов засчитан: `calls = 1`).
- Ошибка подписки для TASK_108 (L5, L7): `requestPermission → 'granted'` + `serviceWorker.register` для `firebase-messaging-sw` отклоняется (`mcp-stub: sw register blocked`).
- Классы C/D/E: эмуляция UA + удаление `window.PushManager` и `window.Notification` (как в Safari вне главного экрана и во встроенных браузерах).
- Wallet на iPhone локально: `meta[shop-wallet-available]` → `true` (на проде он и так `true`).
- Подписанный гость: `permission = 'granted'` + `coffeeos_shop_push_registered_v1 = true`.
- TASK_113: геттер `window.localStorage` бросает `SecurityError` (как Safari с «Блокировать все cookie»).
- Жест TASK_108 — синтетические `pointerup` (`pointerType: touch`) из `evaluate_script`, 7 штук с шагом 150 мс.

## Сценарии

| Задача | Сценарий | Где | Результат | Вердикт |
|---|---|---|---|---|
| поставка | код шагов 6–9 на проде | prod | бандл `application-BYSDfyEI.js` содержит «Уведомления не включены», `dismissed`, `coffeeos_push_diag_v1`, «Не удалось включить уведомления», «Диагностика уведомлений включена/выключена», `order-push-recovery`, `order-open-settings` | ✅ |
| TASK_109 | класс B (вкладка Chrome, push есть) | prod | beacon 204: `notification_state` ≠ unavailable, `push_manager: available`, `inapp_label: none` ([P1](prod/P1_classB_chrome_tab_catalog.png)) | ✅ |
| TASK_109 | класс B: панель + экран заказа | local | панель: «🔔 Уведомление о готовности» на обоих заказах ([L1](local/L1_classB_panel_push_cta.png)); экран заказа: баннер «Разрешить уведомления» + CTA ([L2](local/L2_classB_order_banner_and_cta.png)) | ✅ |
| TASK_109 | класс C (iPhone Safari, не с главного экрана) | prod | beacon: `os_family: ios`, `standalone: browser`, `notification_state: unavailable`, `push_manager: unavailable`; push-CTA / баннера / подсказок нет ([P3](prod/P3_classC_iphone_safari_catalog.png)) | ✅ |
| TASK_109 | класс C: панель + экран заказа, Wallet выкл. | local | панель: `accepted` — только «Отменить заказ», `preparing` — только «Чат с поддержкой» ([L10](local/L10_classC_iphone_safari_panel_no_push.png)); экран заказа: без баннера и push-CTA, только чат, без подсказок ([L11](local/L11_classC_iphone_safari_order_no_push.png)) | ✅ |
| TASK_109 | класс C + Wallet вкл. | local | «Карта в Apple Wallet» на обоих заказах, push-CTA 0, «Отменить» и «Чат» на месте ([L14](local/L14_classC_wallet_on_panel_wallet_cta.png)) | ✅ |
| TASK_109 | класс D (Telegram iOS, Instagram iOS) | prod | beacon: `os_family: ios`, `inapp_label: telegram` / `instagram`, push недоступен; push-CTA / баннера / подсказок нет ([P4](prod/P4_classD_telegram_ios_catalog.png)) | ✅ |
| TASK_109 | класс D: панель | local | Telegram iOS: «Отменить заказ» + «Чат с поддержкой», push-CTA 0, баннера и подсказок нет ([L12](local/L12_classD_telegram_ios_panel_no_push.png)) | ✅ |
| TASK_109 | класс E (Telegram Android, Instagram Android, `; wv)`) | prod | beacon: `os_family: android`, `inapp_label: telegram` / `instagram`, push недоступен; push-CTA / баннера / подсказок нет ([P5](prod/P5_classE_telegram_android_catalog.png)) | ✅ |
| TASK_109 | класс E: панель | local | Telegram Android: «Отменить заказ» + «Чат с поддержкой», push-CTA 0 ([L13](local/L13_classE_telegram_android_panel_no_push.png)) | ✅ |
| TASK_109 | `#/order/:id` — `denied` | local (настоящий `denied` Chrome) | «Уведомления запрещены в настройках браузера» + «Открыть настройки» → инструкция «Откройте настройки сайта в браузере → Уведомления → Разрешить для этого сайта»; «Смотреть готовность» нет ([L4](local/L4_order_denied_recovery.png)) | ✅ |
| TASK_109 + TASK_90 П2 | `#/order/:id` — `dismissed` | local (подмена) | «Уведомления не включены», кнопки остаются, блока восстановления нет ([L3](local/L3_order_dismissed_not_enabled.png)) | ✅ |
| TASK_109 | `#/order/:id` — подписанный гость | local (подмена) | push-CTA 0, баннера «Разрешить уведомления» нет, «Оформить подписку» нет, только «Чат с поддержкой»; Console пуст ([L15](local/L15_order_subscribed_no_push_no_banner.png)) | ✅ |
| TASK_90 Патч 2 | панель — `dismissed` | local (подмена) | «Уведомления не включены», кнопка остаётся, «Открыть настройки» нет ([L9](local/L9_panel_dismissed_not_enabled.png)) | ✅ |
| TASK_90 Патч 2 | панель — `denied` (не задет) | local (настоящий `denied`) | блок восстановления с «Открыть настройки» + «Смотреть готовность» — как в Патче 1 ([L8](local/L8_panel_denied_recovery_real_chrome.png)) | ✅ |
| TASK_108 | без флага — ошибка по нажатию | local (подмена) | «Не удалось включить уведомления. Попробуйте ещё раз», пошагового лога нет ([L5](local/L5_order_error_no_flag.png)) | ✅ |
| TASK_108 | жест 7 нажатий / 3 с на «Заказ» | local | флаг `coffeeos_push_diag_v1`: `null → "1"`, подтверждение «Диагностика уведомлений включена» (по выводу скрипта; скрин см. prod) | ✅ |
| TASK_108 | с флагом — лог | local (подмена) | шаги 1–7 + «ОШИБКА на шаге 7: mcp-stub: sw register blocked», с переносами строк ([L7](local/L7_order_error_with_flag_log.png)) | ✅ |
| TASK_108 | жест на проде | prod | `#/order/<несуществующий>`: флаг `null → "1"`, «Диагностика уведомлений включена» ([P2](prod/P2_task108_gesture_confirm_prod.png)); повторный жест → `"0"`, «Диагностика уведомлений выключена» | ✅ |
| TASK_113 | заблокированное хранилище — витрина | prod | каталог рисуется, все `/shop/api/*` 200 (401 `/profile` — гость), beacon 204 ([P6](prod/P6_task113_storage_blocked_catalog.png)) · **Console: 2× `Uncaught (in promise) SecurityError`** — из `codeblackPendingOrder.js` (`hr()` = `defaultStorage()` в бандле, вызов из `loadPendingOrder`) | ❌ (не поставка) |
| TASK_113 | заблокированное хранилище — панель + кнопка | local | панель с обоими заказами, «🔔 Уведомление о готовности» → `requestPermission` вызван 1 раз → «Уведомления не включены»; новых ошибок от нажатия нет; те же 2× `SecurityError` со старта ([L16](local/L16_task113_storage_blocked_panel_button.png)) | ✅ код TASK_113 · ❌ Console |
| 🚀 1 / TASK_120 | A → B → снова B → A | prod | A: `POST /cart/add` 200 ([a1](prod/P7a1_task120_point_a_cart_1_item.png)) · **B:** `GET /cart` ×2 → `cart_reset: true`, `items: 0`, баннер «Корзина очищена: вы перешли в другую точку» ([a2](prod/P7a2_task120_point_b_cart_reset_banner.png)) · **снова B:** `cart_reset` нет, баннера нет, `set-cookie` нет ([a3](prod/P7a3_task120_point_b_again_no_banner.png)) · **A:** `items: []`, `total: 0`, баннера нет ([a4](prod/P7a4_task120_back_to_a_empty_cart.png)) · 18 с опроса + перезагрузка — по-прежнему пусто ([a5](prod/P7a5_task120_point_a_after_poll_reload_empty.png)) | ✅ |
| 🚀 1 / TASK_112 | beacon один раз за вкладку | prod | `POST /shop/api/environment_events` 204 при первой загрузке; после перезагрузки той же вкладки второго нет (класс C) | ✅ |
| 🚀 1 | `/config`, `/tenants`, read-only без `set-cookie` | prod | `/config`, `/tenants` 200 во всех прод-профилях · `/config` и `/orders/active` с cookie — без `set-cookie`; повторный `GET /cart` в B — без `set-cookie`; `set-cookie` только у документа `/shop` и у `GET /cart` со сбросом — как в v518 | ✅ |
| все | Console / Network | prod + local | JS-исключений нет, кроме 2× `SecurityError` при заблокированном хранилище (выше) · 5xx на `/shop/api/*` — 0 · в Console только 401 `/profile` (гость) и 404 `/uploads/*` (известно, ISSUES) | ✅ |

## Найдено попутно

### 🔴 `codeblackPendingOrder.js` падает при заблокированном хранилище (не регрессия v520)

- **Что:** `app/frontend/lib/codeblackPendingOrder.js:9-12` — `defaultStorage()` делает `typeof localStorage` и `return localStorage` без `try/catch`. Если браузер бросает на доступе к хранилищу (Safari с «Блокировать все cookie», часть встроенных браузеров), `loadPendingOrder` / `savePendingOrder` / `clearPendingOrder` бросают `SecurityError`.
- **Проявление (проверено):** на старте витрины восстановление платежа после СБП (`recoverPendingPayment` → `loadPendingOrder`) даёт 2× `Uncaught (in promise) SecurityError`; витрина и панель заказов при этом работают. Источник подтверждён стеком в init script: `hr()` в `application-BYSDfyEI.js` = `defaultStorage()`.
- **Риск (по коду, не воспроизводилось — «Оплатить» не нажимали):** `shopSbpPay.js:160-189` `beginSbpBankRedirect` вызывает `savePending()` до `go(paymentUrl)` → в таком браузере исключение до редиректа, гость не попадёт в банк по СБП.
- **Почему не в TASK_113:** TASK_113 закрывал только `orderStatusNotifyActions.js` (push/Wallet), запасное хранилище — TASK_114. Файл не менялся с `d4f43691` (CODE:BLACK).
- **Варианты (решение владельца):** hotfix — `defaultStorage()` под `try/catch` (как в TASK_113) + запись pending в своём `try/catch`, чтобы редирект в банк шёл всегда; или в TASK_114; или принять.

### Rack::Attack при приёмке

7–8 параллельных прод-профилей с опросом раз в 8 с упёрлись в `shop/api` 150/мин с одного IP → 429 на одной загрузке точки B; вкладки закрыты, TASK_120 повторён с нуля в новом профиле. Локально — то же (5 вкладок с 127.0.0.1). Поведение лимита ожидаемое, не баг.

### Наблюдение (не баг)

Подписанный гость в **панели** видит «🔔 Уведомление о готовности» на заказе `accepted` (`orderStatusCtaMachine.js` — для `accepted` push-CTA не зависит от подписки; для `preparing`/`ready` — скрыт). Так было до TASK_109 (отмечено security-review шага 9); требование «подписанный гость кнопку не видит» в TASK_109 — про экран заказа, там ✅.

## Пачка приёмки

- **Fly logs:** живой `fly logs -a coffeeos` 07:10:39–07:20:26 UTC (2611 строк, [выжимка](fly_logs_summary.txt)): 2xx 513, 4xx 18 (все 401 `/shop/api/profile` гостя), **5xx 0**, `Exception`/`FATAL`/`PreparedStatementCacheExpired` **0**, `RoutingError` 57 (`/uploads/*`, favicon — известно), `POST environment_events` 9 · смена машин 07:10:39 — штатный SIGINT, Solid Queue остановлен gracefully
- **Sentry 24h:** по CoffeeOS — 0 issues (5 нерешённых — все `PARKOUR-AM-*`, другой проект)
- **Neon:** skip — миграций нет, PSCE в логах 0
- **УК лента Point A:** skip — нужен вход в УК, паролем не входим
- **Fly MCP Point A:** **FAIL по Console в TASK_113** (причина вне поставки), остальное PASS

## Не проверено здесь

- 👤 Ручной тест на iPhone с видимой диагностикой (условие 🚀 2) — **пропущен по решению владельца**.
- Настоящие устройства (iPhone Safari / PWA, Telegram, Instagram) — только эмуляция UA + подмены API в Chrome; настоящий системный диалог уведомлений не открывался (кроме настоящего `denied` профиля Chrome).
- Сценарии экрана заказа и панели на проде — нет активного заказа без оплаты; проверены локально на том же коде.
- Класс A (установленное PWA) — не эмулировался.
- Успешная подписка до токена FCM — не проверялась (без настоящего push-сервиса).
- `WALLET_FORCE_UNAVAILABLE` — не выставлялся (отдельный апрув).
- Строки `environment_events` в базе прода — не смотрели (read-only `fly ssh` не делали; beacon 204 ×9 в логах).
