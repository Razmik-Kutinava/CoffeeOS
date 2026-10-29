# Fly v523 — 🚀 4 (шаги 10–11 очереди Push + SMS) · 2026-10-29

**Итог: PASS, блокеров нет.** Деплой прошёл (v523, web 1/1, обе миграции применены в `release_command`). Всё, что поставлено в шагах 10 и 11, работает: плашка установки на iPhone и Android, запуск с иконки, карточка перед системным запросом уведомлений в панели заказов и на экране заказа, события воронки принимаются сервером. Найдено 4 мелких наблюдения (UX/косметика) — ниже, решение владельца; багов, ломающих сценарий, нет.

**Коммит:** `48412465` (код шагов 10–11 — `5201db60..48412465` и `a22c1e26..2f16d293`) · CI [40881719995](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40881719995) + Semgrep + CodeQL green · HEAD = `origin/develop`
**Deploy:** [40883608713](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40883608713) (13:37:17–13:41:10 UTC) · release **v523**, машины на v523 с 13:41:08 UTC · бандл `application-BY_k_aDU.js` · апрув владельца 2026-10-29
**Миграции:** `20261029090000` (TASK_110, +6 `event_kind`) и `20261029120000` (TASK_111, +4 `event_kind`) — только CHECK `chk_shop_environment_events_event_kind`, колонки не менялись · `release_command` completed successfully · на проде `install_banner_*`, `pwa_first_launch`, `session_open` → 204 (до миграции CHECK отклонил бы новые виды) · `PreparedStatementCacheExpired` в логах 0 — перезапуск Neon не понадобился

## Как проверяли

Chrome DevTools MCP, каждый сценарий — отдельный изолированный профиль (чистый гость). Прод `coffeeos.fly.dev`, Point A `2fdee1ac-…`. Без OTP, без PAN, «Оплатить» не нажималась, профиль Арама не трогали.

**Прод / локально.** Карточке TASK_110 нужен активный заказ в «Принят»/«Готовится» — на проде без оплаты не получить, поэтому её сценарии — **локально** (`bin/rails server -p 3001` + `bin/vite dev`, тот же код `48412465`, Demo Point A `8c7f5bc7-…`, тестовые заказы v520 `9ba9bdb4-…` #202610-0002 `accepted` и `ae0ed429-…` #202610-0001 `preparing`, гость привязан через `POST /session/reconnect`). На проде — TASK_111 целиком, код TASK_110 в бандле, приём событий сервером.

**Подмены (init script) — честно:**
- iPhone Safari / Telegram iOS: эмуляция UA + удаление `window.PushManager` и `window.Notification` (как в Safari вне главного экрана).
- Запуск с иконки: `navigator.standalone = true` (Notification/PushManager оставлены — как в установленном приложении iOS 16.4+).
- Android установка: синтетическое `beforeinstallprompt` с `userChoice = { outcome: "dismissed" }`.
- Разрешение уведомлений: `Notification.permission = "default"`, `requestPermission` → `default` (закрыл без выбора) или `denied`; счётчик вызовов читается **сразу после** `click()` — проверка синхронности (TASK_99).
- Локально Firebase не настроен (мета-тегов нет) → для экрана заказа подставлены фиктивные `firebase-*` мета-теги; до системного запроса код Firebase не вызывается. Wallet — мета `shop-wallet-available` `true`/`false`.

## Сценарии

| Задача | Сценарий | Где | Результат | Вердикт |
|---|---|---|---|---|
| поставка | код шагов 10–11 в бандле | prod | есть «Уведомим, когда заказ будет готов», «Не сейчас», `coffeeos_shop_push_preprompt_v1`, `push_preprompt_shown`, `push_permission_default`, «Установить CoffeeOS на главный экран», «Как установить CoffeeOS», `pwa_first_launch`, `install_banner_dismiss`; старого баннера «Разрешить уведомления» нет | ✅ |
| TASK_111 | iPhone Safari — плашка | prod | «Установить CoffeeOS на главный экран» + «Как установить» + ×, `data-variant=ios`; `install_banner_shown` и `session_open` → 204 ([P1](prod/P1_ios_safari_install_banner.png)) | ✅ |
| TASK_111 | «Как установить» | prod | инструкция раскрывается внутри плашки сверху, 3 шага, «Понятно» ([P2](prod/P2_ios_how_to_install_panel.png)); `install_banner_tap` на каждое раскрытие; «Понятно» и свайп вверх (синтетические touch, 80 px) закрывают инструкцию, плашка остаётся | ✅ |
| TASK_111 | крестик → та же сессия → новая сессия | prod | × скрывает плашку, `install_banner_dismiss`, отметка в `sessionStorage` (в `localStorage` нет); перезагрузка вкладки — плашки нет; новая вкладка того же профиля — плашка снова (`ios`) | ✅ |
| TASK_111 | запуск с иконки (standalone) | prod | плашки нет ([P3](prod/P3_ios_standalone_no_banner.png)); `pwa_first_launch` → 204 (`standalone: standalone`); `POST /pwa_install` → 401 у гостя, тихо (ошибок и сообщений нет); повторный запуск — ни второго `pwa_first_launch`, ни второго `/pwa_install` | ✅ |
| TASK_111 | Android — плашка и отказ | prod | «Установить» + × (`android`) после `beforeinstallprompt` ([P4](prod/P4_android_install_banner.png)); «Установить» → `prompt()` 1 раз, отказ → плашка закрыта до конца сессии, `install_banner_tap` | ✅ |
| TASK_111 | Telegram на iPhone | prod | плашки нет | ✅ |
| TASK_110 | панель — автопоказ | local | карточка сама на #0002 (`accepted`), на #0001 нет — одна на экран; `push_preprompt_shown`; системный запрос не вызывался ([L1](local/L1_panel_preprompt_autoshow.png), [L2](local/L2_panel_preprompt_scrolled_into_view.png)) | ✅ (см. наблюдение 2) |
| TASK_110 | «Не сейчас» | local | карточка скрыта, `push_preprompt_later`, на устройстве `{dismissals: 1, lastDismissedOrderId: #0002}`; после перезагрузки на #0002 сама не всплывает, на #0001 — всплывает | ✅ |
| TASK_110 | 🔔 на закрытом заказе | local | карточка открывается на #0002 без системного запроса ([L3](local/L3_panel_two_cards_after_bell.png)) | ✅ (см. наблюдение 3) |
| TASK_110 | «Включить» → закрыл без выбора | local | `requestPermission` вызван **синхронно** в том же нажатии (1 вызов сразу после `click`); `push_preprompt_accept` + `push_permission_default`; «Уведомления не включены», блока «Открыть настройки» нет; засчитано как «Не сейчас» (`dismissals: 2`) | ✅ |
| TASK_110 | лимит 3 | local | после 3-го «Не сейчас» и перезагрузки автопоказа нет ни на одном заказе; по 🔔 карточка открывается | ✅ |
| TASK_110 | экран заказа — автопоказ | local (Firebase-мета подставлены) | карточка вместо баннера «Разрешить уведомления» (баннера нет), `push_preprompt_shown` ([L4](local/L4_order_screen_preprompt.png)); без Firebase-меты автопоказа нет — по коду `pushAvailable = firebaseClientConfigured()`, как у прежнего баннера | ✅ |
| TASK_110 | экран заказа — «Включить» → запрет | local | синхронный `requestPermission`; `push_preprompt_accept` + `push_permission_denied`; «Уведомления запрещены в настройках браузера» + «Открыть настройки» ([L5](local/L5_order_screen_denied_recovery.png)) | ✅ |
| TASK_110 + TASK_111 | iPhone с иконки + Wallet | local | «Карта в Apple Wallet» на обоих заказах, push-CTA и карточки нет, плашки установки нет, `pwa_first_launch` | ✅ |
| TASK_110 | iPhone с иконки без Wallet | local | 🔔 + карточка; «Включить» → `requestPermission` синхронно (инвариант TASK_99 на эмуляции) | ✅ |
| все | Console / исключения | prod + local | `error` / `unhandledrejection` — 0 во всех сценариях; Console — только 401 `/profile` (гость) и 404 `/uploads/*`, favicon (известно) | ✅ |

## Наблюдения (не блокеры, решение владельца)

1. **Плашка установки закрывает заголовок первой категории каталога.** iPhone 390×844, прокрутка 0: плашка 52–105 px, заголовок «Черный кофе» 72–100 px ([P1](prod/P1_ios_safari_install_banner.png)). Причина та же, что у ISSUES 🟡 «перекрывает заголовок товара» (`position: fixed; top: 3.25rem` в `ShopPwaBanner.svelte`); теперь плашку видит каждый гость iPhone в Safari, а не только Android с доступной установкой. Решение по перекрытию на `/spec` TASK_111 — «не в этой задаче» → дополнено в ISSUES 🟡.
2. **`push_preprompt_shown` уходит, даже если карточку не видно.** В свёрнутой шторке список заказов (`.oss__list`) 122 px; карточка первой строки — на 825–909 px при обрезке на 805 px, видна только после прокрутки списка. Это по ТЗ (Subtask 11: «при нехватке места прокручивается внутри списка панели», высоты шторки менять запрещено), но воронка будет считать показы, которые гость не видел.
3. **По 🔔 открывается вторая карточка.** Если на одном заказе карточка открыта автоматически, нажатие 🔔 на другом открывает вторую — на экране две ([L3](local/L3_panel_two_cards_after_bell.png)). ТЗ: «не более одного блока» — для автопоказа (Subtask 1), ручное открытие — «всегда» (Subtask 2); формально не нарушение.
4. **Шаги инструкции iPhone без номеров.** `<ol class="ios-install__steps">` — `list-style: none` из глобальных стилей ([P2](prod/P2_ios_how_to_install_panel.png)). Косметика.

## Пачка приёмки

- **Fly logs** ([выжимка](fly_logs_summary.txt)): живой поток 13:40–13:50 UTC (1855 строк) + буфер до 13:51: 2xx 379, 4xx 11 (401 гостя), **5xx 0**, `Exception`/`FATAL` 0, `PreparedStatementCacheExpired` 0, `POST environment_events` 14 — 422 нет
- **Sentry 24h:** по CoffeeOS 0 (1 нерешённая — `PARKOUR-AM-5`, другой проект)
- **Neon:** skip (MCP) — миграции только CHECK, PSCE 0, 5xx 0
- **УК лента Point A:** skip — нужен вход в УК, паролем не входим
- **Fly MCP Point A:** **PASS**

## Не проверено здесь

- 👤 Приёмка на настоящих Android и iPhone (установленное приложение) — условие очереди после 🚀 4, закрывает G4 TASK_99. Здесь — эмуляция UA и подмены API в Chrome; настоящий системный диалог уведомлений не открывался.
- Сценарии карточки на проде — нет активного заказа без оплаты; проверены локально на том же коде.
- Успешная подписка до токена FCM, «Готов» без push-CTA (нет локального заказа в `ready`) — покрыто unit-тестами.
- Вошедший гость с `pwa_installed: true` в профиле (плашка не показывается) — не проверялось вживую, без OTP.
- Строки `shop_environment_events` в базе прода — не смотрели; приём подтверждён 204 и логами.
- `WALLET_FORCE_UNAVAILABLE` — не выставлялся (отдельный апрув).
