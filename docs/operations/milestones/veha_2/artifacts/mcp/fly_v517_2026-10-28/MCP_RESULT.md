# Fly v517 — 🚀 1 (очередь Push + SMS, шаги 1–5) · 2026-10-28

**Итог: FAIL — приёмка остановлена, отката и hotfix нет.** FAIL 1 (500 после миграции) закрыт перезапуском compute Neon в 14:35 UTC; FAIL 2 (TASK_120) — патч отдельным шагом (решение владельца).

**Коммит:** `7413a427` (код — `a694f98b` и раньше; после — только docs) · CI [40701310484](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40701310484) + Semgrep [40701310485](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40701310485) + CodeQL [40701310481](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40701310481) green · deploy [40703896556](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40703896556) (4м54с) · release **v517** complete 14:18 UTC · release_command (миграции) OK · web 1/1 health passing
**В поставке относительно v516:** TASK_112 (снимок окружения, миграция `20261028120000`), TASK_92 Патч 1–2 (push ready / отмена), TASK_115 (`tenants.code_black_member`, миграция `20261028130000`), TASK_120 (корзина при смене точки), RUBY-1R (`Client-IP`), CI-раннер 24.04 + гемы `crass`/`net-ssh`/`rubocop`.
**До деплоя:** `git status` чистый, HEAD = `origin/develop` = `7413a427` · crit-audit `CLEAN`, `last_audited_sha` = `a694f98b`, после него кода нет · ISSUES «🔴 Открыто» — блокеров деплоя нет (🔴 «Связь с поддержкой» — на проде с v506).

## Как проверяли

Headless Chrome через CDP (эквивалент DevTools MCP) на проде `coffeeos.fly.dev`, Point A (`2fdee1ac-…`), каждый сценарий — чистый гостевой профиль. Скрипт [`verify_prod.mjs`](verify_prod.mjs): Network (статусы всех `/shop/api/*`, тела ответов `/cart`), Console, скрины. Прогон «до» на v516 — `before/`, «после» на v517 — `after/`. Без OTP, без PAN, «Оплатить» не нажималась, профиль Арама не трогали. База — `fly ssh` + `bin/rails runner` в транзакции `READ ONLY` (`SHOW transaction_read_only` = on).

**Ограничение стенда:** на проде одна торговая точка (Витрина А) + кухня `Demo Prep Kitchen` (`d47165db-…`, active). Переключателя точек в шапке нет (`/shop/api/tenants` отдаёт одну точку). Для TASK_120 точкой B взята кухня: shop API находит точку по id без фильтра по типу, витрина с её `tenant_id` открывается (скрин 07). Новую точку на проде не создавали.

## До / после

| | v516 (до) | v517 (после) |
|---|---|---|
| Fly | v516, образ `01M4NAG0…` | v517, образ `01M61DS6…` |
| Миграции (последние) | `20261005140000` | `20261028130000`, `20261028120000` |
| `tenants.code_black_member` | нет | boolean NOT NULL default false + CHECK |
| `shop_environment_events` | нет | таблица + view |
| Витрина Point A | 200, «Самара, ул. Куйбышева, 78», «Профиль ID», 0₽ | то же |
| `POST /shop/api/environment_events` | не отправлялся | 1 за вкладку, 204 |

## Итог по задачам

| Задача | Что проверяли | Результат | Вердикт |
|---|---|---|---|
| **TASK_112** снимок окружения | один beacon за вкладку, перезагрузка без дубля, строка в базе | `POST /shop/api/environment_events` (Ping) → **204**, после `Page.reload` всего 1 (флаг `coffeeos_env_session_open_v1` = 1) · в базе 4 строки = 4 профиля браузера, все `point_id` = Point A; колонки только флаги (`os_family`, `standalone`, `notification_state`, …), `ua_snippet` null, данных гостя нет · view `v_shop_environment_events` отдаёт `point_name` | ✅ |
| **TASK_115** CODE:BLACK | колонка в базе | `code_black_member` boolean NOT NULL default false, CHECK `chk_tenants_code_black_member_sales_point` есть; у обеих точек `false` · `/admin/tenants` не открывали (паролем УК не входим) | ✅ |
| **RUBY-1R** | `Client-IP: 1.2.3.4` | `/shop?tenant_id=…` → **200**, `/up` → 200 (до — не воспроизводили, чтобы не шуметь в Sentry) | ✅ |
| **TASK_120** корзина при смене точки | A → B (кухня) → снова B → A | сброс срабатывает: `GET /cart?tenant_id=<B>` → `cart_reset: true`, `items: 0`, баннер «Корзина очищена: вы перешли в другую точку» ([07](after/07_task120_point_b_cart_reset_banner.png)), `coffeeos_shop_cart_v1` — `items: []` · **но сброс не держится:** повторный заход в B → снова `cart_reset: true` и баннер ([07b](after/07b_task120_point_b_empty_cart_no_banner.png)); возврат в A → **старая корзина A вернулась** (`items: 1`), «добавить» даёт 2 шт. (20₽). В другом прогоне — обратное: корзина A опустела без `cart_reset`. Причина — гонка cookie-сессии (ниже) | ❌ |
| **Общее** витрина | Console, `/shop/api/*`, каталог/шапка/шторка | каталог, шапка, шторка как на v516 ([01](after/01_catalog_point_a_412x915.png) vs [before/01](before/01_catalog_point_a_412x915.png)) · Console: JS-исключений нет; только 401 `/profile` (гость), 404 `favicon`/`uploads` (известно, ISSUES) · **`/shop/api/config` и `/shop/api/tenants` — плавающий 500** | ❌ |
| **TASK_92** Патч 1–2 | push ready / отмена | skip — в браузере не проверяется (нужен FCM на телефоне); Android E2E у владельца (Subtask 16) | skip |

## FAIL 1 — 500 на `/shop/api/config` и `/shop/api/tenants` после миграции

`ActiveRecord::PreparedStatementCacheExpired: ERROR: cached plan must not change result type` · стек: `Shop::CustomerTenantHistory#city_sales_points` (`customer_tenant_history.rb:62`) внутри `Rls::GucContext.with_local_guc` (транзакция) ← `TenantsController#index` / `ConfigController#show` · выдержка — [`after/fly_logs_psce_excerpt.txt`](after/fly_logs_psce_excerpt.txt).

- Механизм: миграция TASK_115 добавила колонку в `tenants`; `DATABASE_URL` идёт через пул Neon (`-pooler`), `prepared_statements` по умолчанию включены. Подготовленный до миграции `SELECT tenants.*` остался на серверных соединениях пула → у части соединений запрос падает. Вне транзакции Rails повторяет запрос сам, внутри — нет, отсюда 500.
- Масштаб в окне лога 14:22–14:27 UTC: 6 ответов 500 (14:23 ×3, 14:24 ×1, 14:27 ×2), только эти два эндпоинта; на остальных — 2xx. Само не прошло за ~9 минут после выкладки.
- В Sentry не попадает: `Shop::Api::ErrorHandler` перехватывает `StandardError` и только пишет в лог.
- Для гостя: при 500 на `/config` шапка уходит в офлайн-режим (адрес из кэша, `bootstrapShopTenant` → `applyOfflineFallback`); `/config` отдаёт ещё настройки оплаты, push и график — как витрина ведёт себя без них при оформлении, не проверял. При 500 на `/tenants` — только текущая точка. Каталог и корзина отвечали 2xx. Панели персонала в окне лога запросов не делали — затронуты ли они, не проверено.

**Закрыто 14:35 UTC:** владелец перезапустил compute в консоли Neon (сброс соединений пула). Повторная проверка 14:35–14:40 UTC: в логе Fly 0 `PreparedStatementCacheExpired`, 0 ответов 5xx на 252 ответа 2xx, `/config` + `/tenants` обработаны 39 раз без ошибок; в браузере (`after_neon_restart/`) `/config` 7/7 и `/tenants` 14/14 → 200, beacon TASK_112 → 204, JS-исключений 0. **Впредь:** любая миграция, меняющая колонки таблицы, которую читают внутри транзакции, повторит ошибку — после такого деплоя перезапускать compute Neon или выключить `prepared_statements` (backlog в ISSUES).

## FAIL 2 — TASK_120: сброс корзины затирается параллельными запросами

Сессия — `cookie_store` (`expire_after: 90.days`): каждый запрос, читающий сессию, возвращает её целиком в `Set-Cookie`. При загрузке витрины параллельно идут `/cart`, `/config`, `/tenants`, `/orders/active`, `/frequent_products`; запрос, начатый со старым снимком (корзина A + метка A) и завершившийся после сброса, возвращает корзину A обратно. Локальные тесты шлют запросы последовательно, поэтому гонку не ловят. Хронология прогона 14:26–14:27 — `after/results_task120_kitchen.json` → `timeline`.

## Пачка приёмки

- **Sentry 24h:** по CoffeeOS — 0 новых (единственная нерешённая в организации — `PARKOUR-AM-4`, другой проект) · 500 из FAIL 1 в Sentry не видны (см. выше)
- **Fly logs:** 500 `PreparedStatementCacheExpired` (FAIL 1); прочее — 404 `uploads`/`favicon` (известно); release_command OK, web health 1/1
- **Neon Monitoring:** skip — Neon MCP требует авторизации, в консоль не входили
- **УК лента Point A:** skip — нужен вход в УК, паролем не входим
- **Fly MCP Point A:** **FAIL** (TASK_112 ✅, TASK_115 ✅, RUBY-1R ✅, TASK_120 ❌, общее ❌ из-за 500, TASK_92 skip)

## Найдено попутно (не из поставки)

- Витрина открывается с `tenant_id` кухни (`production_kitchen`): `Shop::Api::BaseController#with_shop_tenant!` ищет точку только по id — показывает каталог и адрес кухни ([07](after/07_task120_point_b_cart_reset_banner.png)).
- `coffeeos_shop_cart_v1` хранит `cart_reset: true` внутри `payload` после сброса — косметика, на поведение не влияет.

## Не проверено здесь

- Настоящий переход между двумя торговыми точками через шапку (на проде одна точка).
- Android E2E TASK_92 Патч 1–2 (у владельца).
- `/admin/tenants` глазами (только если владелец сам залогинен).
