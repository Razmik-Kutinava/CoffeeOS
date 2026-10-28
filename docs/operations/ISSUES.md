# ISSUES

> **Агент на старте:** только `## 🔴 Открыто`. Resolved → [`issues/archive/`](issues/archive/).

## 🔴 Открыто

| ID | Статус | Блокер |
|----|--------|--------|
| Fly v517: 500 `PreparedStatementCacheExpired` на `/shop/api/config` и `/shop/api/tenants` (2026-10-28, 🚀 1) | 🟢 | **на проде закрыто 14:35 UTC** перезапуском compute Neon (владелец): 14:35–14:40 — 0 PSCE, 0 5xx на 252 2xx · **долг:** повторится после любой миграции, меняющей колонки таблицы, читаемой в транзакции → после такого деплоя перезапуск compute или `prepared_statements: false` (решение владельца) · история: | после миграции TASK_115 (колонка в `tenants`) часть запросов падает «cached plan must not change result type»: `DATABASE_URL` через пул Neon (`-pooler`), `prepared_statements` по умолчанию включены → подготовленный до миграции `SELECT tenants.*` живёт на серверных соединениях пула; `Shop::CustomerTenantHistory#city_sales_points` (`customer_tenant_history.rb:62`) выполняется в транзакции `Rls::GucContext.with_local_guc` → Rails не повторяет → 500 · 6 ответов 500 за 14:22–14:27 UTC, само не прошло за ~9 мин · в Sentry не видно (`Shop::Api::ErrorHandler` глотает `StandardError`) · панели персонала не проверены · решение владельца: сброс соединений пула / `prepared_statements: false` / ждать · [MCP_RESULT](milestones/veha_2/artifacts/mcp/fly_v517_2026-10-28/MCP_RESULT.md) |
| TASK_120 на проде: сброс корзины затирается параллельными запросами (2026-10-28, 🚀 1) | 🔴 | сессия `cookie_store` (`expire_after: 90.days`) → каждый запрос, читающий сессию, возвращает её целиком; при загрузке витрины параллельно идут `/cart`, `/config`, `/tenants`, `/orders/active`, `/frequent_products` → ответ со старым снимком (корзина A + метка A) приходит после сброса и возвращает корзину A · на проде: повторный заход в B — снова `cart_reset` и сообщение, возврат в A — старая корзина; в другом прогоне корзина A пропала без `cart_reset` · локальные тесты шлют запросы последовательно — не ловят · решение владельца · [MCP_RESULT](milestones/veha_2/artifacts/mcp/fly_v517_2026-10-28/MCP_RESULT.md) |
| Витрина открывается для кухни (2026-10-28, приёмка v517) | 🟡 | `Shop::Api::BaseController#with_shop_tenant!` ищет точку только по id, без типа → `/shop?tenant_id=<production_kitchen>` показывает каталог и адрес кухни · было и до v517 · отдельная задача |
| RLS в production не действует (2026-10-28, TASK_119 этап 1) | 🟡 | prod read-only: роль приложения `neondb_owner` — `rolbypassrls = true` и владелец всех 98 таблиц → политики к ней не применяются; RLS включён только на 8 таблицах (миграции с 2026-06), на `orders`/`payments`/`users`/`sessions` и ещё 24 таблицах из stage 0–8 выключен; нет политик изоляции stage 0–8 и `20260320120001/2` · изоляция точек держится только на коде · не авария (так было всегда, прод работает), но расходится с моделью в миграциях · решение — заказчик (этап 2 TASK_119, шаг 13a / Q3 очереди) · [PROD_QUERIES_RESULT](milestones/veha_2/artifacts/production_rls_verify/PROD_QUERIES_RESULT.md) · включать RLS — только после правки мест из [CODE_BYPASS_INVENTORY](milestones/veha_2/artifacts/production_rls_verify/CODE_BYPASS_INVENTORY.md) |
| CI красный: нет Ruby 3.4.8 на `ubuntu-latest` (2026-10-28, /review TASK_118 S9) | 🟡 | с 2026-10-19 `ubuntu-latest` = Ubuntu 26.04, `ruby/setup-ruby` там собирает только последний патч (3.4.12) → `Unavailable version 3.4.8` (`.ruby-version`), падают все 5 джоб `ci.yml` (run 40652639011) · чин: `ci.yml` `runs-on: ubuntu-24.04` (как в `db-backup.yml`) · долг: поднять Ruby до 3.4.12 (`.ruby-version` + `Dockerfile` + `Gemfile.lock`) отдельной задачей и вернуть `ubuntu-latest`, пока GitHub не снял образ 24.04 · + `scan_ruby` (run 40652845599): новые advisory bundler-audit → `bundle update --conservative`: `crass` 1.0.7→1.0.8 (через `loofah`, прод), `net-ssh` 7.3.1→7.3.8 (через `kamal`), `rubocop` 1.85.1→1.92.1 (dev; больше не тянет `mcp` 0.25 с SSRF-advisory) · локально bundler-audit 0, rubocop по файлам из git 0 |
| Telegram-алерты не уходят | 🟡 | на Fly есть `TELEGRAM_BOT_TOKEN`, нет `TELEGRAM_CHAT_ID` → `TelegramAlertJob#perform` выходит сразу (1–3 мс на prod 2026-10-05 15:45 UTC), алерты о зависших платежах теряются · нужен chat_id от владельца → `fly secrets set TELEGRAM_CHAT_ID=…` |
| Шапка витрины выше отступа контента (2026-10-11, TASK_107) | 🟡 | `App.svelte:157` `<main>` — фиксированный `pt-[4.5rem]` (72px), а шапка растёт с длиной адреса: при адресе в 2 строки ~74px (было и до TASK_107), на <360px после TASK_107 («Профиль ID» 66px вместо иконки) очень длинный адрес → 3 строки, шапка 93px закрывает ~21px верха страницы · [MEASURE](milestones/veha_2/artifacts/shop_header_profile_id/MEASURE.md) · проверить реальный адрес Point A на Fly · фикс — отдельная задача (отступ по фактической высоте шапки) |
| `payment_error_matrix_test.mjs` красный (2026-10-11, найдено на TASK_105) | 🟡 | 17/24: 7 тестов TASK_100 `classifyPaymentError` получают `undefined` вместо `insufficient_funds`/`card_expired`/`too_many_attempts`/`card_declined` · **причина (2026-10-11, перед v516): не продукт, а среда** — Node 22 даёт глобальный `navigator` без `onLine` → `shopPayFsm.js:184` `!navigator.onLine` = офлайн → `NET_ERROR`; с `--import` `navigator.onLine = true` тест 24/0; `shopPayFsm.js` не менялся с `060ef61f` (TASK_100, уже на проде), в браузере `onLine === true` · фикс — в тесте задать `navigator.onLine` через `Object.defineProperty` · + TASK_105 /regress: `shop_telegram_webview_ux_perf_test.mjs` не грузится на Node 22 (`globalThis.navigator = …` — у `navigator` только getter, `:39`) → фикс теста через `Object.defineProperty`, падает и до TASK_105 |
| Устаревшая подсказка «+сумма» на checkout (2026-10-11, приёмка v516) | 🟡 | `Checkout.svelte:794` «Оплата — кнопка «+сумма» в шторке заказа внизу экрана», а после TASK_106 кнопка — «0₽» без «+» · только текст, вне scope TASK_106 · поправить отдельной мелочью по решению владельца |
| Плашка «Установить CoffeeOS» перекрывает заголовок товара (2026-10-11, приёмка v516) | 🟡 | на `#/product/:id` 412×915 install-баннер лежит поверх строки «‹ Название товара» · так же на v515 (`artifacts/mcp/fly_v516_2026-10-11/before/04_product_412x915.png`) — не регресс · отдельная задача |
| ТВ-колонки без фильтра смены (2026-10-06) | 🟡 | `BroadcastTvColumnsJob#orders_for_column` → `Order.for_barista_board` (только tenant + статус, без смены/времени) → на ТВ «Готово» всплывают старые `ready` с мая; `TvBoardsController` (через `BoardOrdersQuery.board_scope`) — со сменой. Данные чистит `platform:prod_data_cleanup`, код — отдельная задача |
| SBP webhook `RATE_LIMITED` | 🟡 | `SbpAccountTokenFromWebhook#call!` проверяет только `BLOCKED`; `SbpAccountTokenStore.persist!` при velocity возвращает `:rate_limited` → `stored.method_hash` → `NoMethodError` в callback (найдено на TASK_102, вне scope) |
| Флак `shop_usercards_phase1_persist_test` | 🟡 | `test_P1_FA_CONFIRMED_without_RebillId_GetState_retry_persists_UserCards` (`:273`) упал 1 раз в общем прогоне 1410 тестов (seed `7965`, 2026-10-06, Quick Repeat Патч 1) · отдельно 4/0 до и после патча · `test/integration/shop --seed 7965` 688/0 → зависимость от порядка/таймингов, не от патча · чинить отдельно |
| UserCards / RebillId | 🟢 | v493 MIR RebillId+Charge PASS · new save_card FA не re-run |
| Checkout UX (Фаза 2) | 🟡 | апрув заказчика |
| SBP 3001 | 🟢 | live init ≠3001 · остаток: bind AccountToken (B) |
| #47 / #35 PWA статусы | 🟡 | Fly v481 MCP PASS · апрув заказчика |
| #79 SBP return + autopay labels | 🟡 | timing «1–3 дня» в WAITING + SBP row |
| #86 SBP PWA recovery | 🟢 | CI green · deploy апрув · Fly MCP + device |
| #87 Quick Repeat status | 🟢 | CI green · deploy апрув · Fly MCP G4 |
| #80 Registration + Callcheck | 🟡 | Callcheck×2 в коде · live ждёт телефон |
| #89 PWA auth Callcheck→SMS | 🟢 | CI green · deploy апрув · G5 Fly |
| TASK_89-UI-EXT phone UI | 🟢 | REVIEW CI green · deploy · G5 |
| TASK_89-POSTCALL-EXT | 🟢 | REVIEW CI green · deploy · G5 |
| #81 Notifications/Wallet/Push | 🟡 | tips CTA wired · Wallet скрыт без certs · denied→#90 |
| #90 WebPush after denied | 🟢 | REVIEW CI green · deploy · G5 |
| #91 post-pay → catalog | 🟢 | REVIEW CI green · deploy · G4 |
| #92 background FCM | 🟢 | REVIEW CI green · deploy · G5 |
| EmailVerification tenant-wide | 🟡 | TTL by tenant+email без session bind · backlog |
| #78 subscription cancel/confirm | 🟢 | CancelService+ConfirmPayment в коде · deploy |
| #82 Cascade SMS + sheet stuck | 🟡 | Патч_1 CI green · deploy → Fly MCP |
| #71 email after pay remember | 🟡 | Fly v481 MCP PASS · апрув заказчика |
| TASK_84 receipt display | 🟢 | REVIEW CI green · G5 Fly после deploy |
| JS legacy fails (найдено на TASK_99 /regress) | 🟡 | до TASK_99 те же (`def97615`): `email_collection_test` «identityReady / canPay depend on phoneVerified» 1 fail · `order_action_buttons_cancel_test` «422/500: force preparing» 1 fail · `personal_cabinet_test` 58 — `[RED]` TDD, не баг. Не push-зона · TASK_106 /regress (2026-10-09): + `repeat_invalid_token_payment_test` 3 fail (`shopPayFsm` G7/#46 `[TDD]`) — те же на `8547b253` до правок · + `sticky_cancel` «applyStickyCancelSuccess #41» 1 |
| Локальный `node_modules` сломан `git worktree` (2026-10-09, TASK_106) | 🟢 | junction `node_modules` во временном worktree → `git worktree remove` / `Remove-Item -Recurse` удалили через него `.bin`, `.package-lock.json`, `@rails/actioncable` → `npm run vite:build` без `.bin` вызывал Ruby-обёртку `vite` → рекурсия ~130 процессов · убиты, `npm install` (lock не менялся) → build 16s OK · правило: в worktree **не** делать junction на `node_modules` (или удалять junction `rmdir` до удаления каталога и проверять) |
| RUBY-1N N+1 `StuckPaymentsCheckJob` | 🟢 | **Fly v506 задеплоен** (`0fa72666`) · regress 10:45 был ещё v505 · Sentry → resolved, ждём ~5 ч (traces 5%) · backlog: 4 тестовых pending по 11 ₽ шлют алерт каждые 15 мин · история: | Sentry perf: 2× `SELECT payments WHERE id` на каждый stuck (job `reload` + `rebill_still_needed?` reload при `save_card=false`). Fix `01efc828` (RED `4e5452d7`) · хвост `save_card=true`: rebill-проверка только для succeeded — RED `6f401fb5` → GREEN `1642a746` · Local payments 146/0 + rebill/UserCards 57/0 · Sentry-событие 04.10 09:00 UTC — ещё код v505 · push → CI → deploy апрув → Sentry закроется |
| Витрина A → табло бариста пусто (2026-10-05) | 🟢 | prod: демо-логины были на дубле `Demo Coffee Point A` (`c1bf2ab1`, создан `demo:seed` 18.09 после переименования Point A) → перепривязаны на `2fdee1ac`, дубль inactive · barista-a видит заказы витрины + live PASS · guard в seed `8ee27e88` на проде (Fly v507) · ждём подтверждение заказчика глазами |
| Шторка «Связь с поддержкой» под CartSheet (2026-10-05) | 🔴 | `SupportContactSheet` (иконка в шапке) и `CartSheet` — обе `z-index: 50`, корзина позже в DOM → видно только затемнение, `✕` недоступен · прод v506 + local iPhone/Android · кроме того safe-area не учтён (16px до края) · код не трогали — ждём задачу заказчика по 4 пунктам · [MEASURE](milestones/veha_2/artifacts/active_orders_receipt_display_restore/customer_preview_2026-10-05/MEASURE.md) |
| Product images `/uploads` 404 | 🟡 | `ProductImageStorage` → `public/uploads` на эфемерном диске Fly, volume нет → фото стираются при деплое (v503: 5 ссылок, 1 файл). Нужно решение: S3/Tigris или volume |

Детали до 2026-08 → [`issues/archive/ISSUES-resolved-through-2026-08.md`](issues/archive/ISSUES-resolved-through-2026-08.md)

---

## Решено недавно

> Новые resolved с 2026-09 — ≤10 строк; при >30 или конце месяца — `/ctx-trim`.

- **2026-10-06 — «Персонал» точки показывал УК-аккаунт**: УК с `tenant_id` точки виден управляющему, edit/update (email/пароль) доступны. Fix `38f20b60` (`point_staff_scope`), deploy [37454878368](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37454878368), prod PASS.
- **2026-10-06 — вход без точки = 500** (RUBY-1Q): УК / владелец франшизы с `tenant_id` NULL → `Current.tenant_id not set for Session`. Fix `ca8f5a2e`, deploy [37451853550](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37451853550), prod PASS.

| ID | Когда | Итог |
|----|-------|------|
| #93 Critical path hardening | 2026-09-18 | Fly v499 · MCP 20/20 PASS · device pay = апрув |
| GH FLY_API_TOKEN | 2026-09-07 | org token · Deploy green |
| Min charge 10₽ | 2026-09-07 | PTS≥10 · Init guard · Fly bump |
| #26 invalid token / pay copy | 2026-09 | v493 MCP PASS · inline «Сбой банка: позже» |
