# Fly v518 — повторный 🚀 1 (TASK_120 Патч 1) · 2026-10-28

**Итог: PASS** — сценарии a–d на проде зелёные: сброс корзины при переходе в другую точку держится, добавленный товар не пропадает под опросом, запросы витрины без изменения сессии cookie не пишут. Попутно найден остаточный путь записи cookie вне scope Патча 1 (установка service worker) — 🟡 в ISSUES, решение владельца, не блокер.

**Коммит:** `727f3429` (код — `0738a924` / `b92b74a4`; после — только docs) · CI [40713781617](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40713781617) на `1f1584f8` + CI/Semgrep/CodeQL на `727f3429` ([40714542249](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40714542249), [40714541581](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40714541581), [40714541226](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40714541226)) green · deploy [40715180459](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40715180459) (3м17с) · release **v518** complete 15:24 UTC, образ `deployment-01M61HNKRQM9DJ6824T0BACA4J` · release_command OK (миграций нет) · web 1/1 health passing
**В поставке относительно v517:** только TASK_120 Патч 1 — `Shop::Api::BaseController#process_action`: запрос `/shop/api/*` с сохранённой cookie, не изменивший сессию → `session_options[:skip]` (без `Set-Cookie`).
**До деплоя:** `git status` чистый, HEAD = `origin/develop` = `727f3429` · CRITICAL_LEDGER `last_audited_sha` = `b92b74a4`, вердикт CLEAN, `git diff --stat b92b74a4..HEAD -- app lib db config` пусто · ISSUES «🔴 Открыто» — новых блокеров нет (🔴 TASK_120 — то, что катим; 🔴 «Связь с поддержкой» — на проде с v506) · Fly v517.

## Как проверяли

Headless Chrome через CDP на `coffeeos.fly.dev`, Point A (`2fdee1ac-…`), точка B — кухня `d47165db-…` (на проде одна торговая точка, как в v517; новых точек не создавали). Каждый сценарий — чистый гостевой профиль. Скрипт [`verify_prod.mjs`](verify_prod.mjs) (основа — v517) пишет статусы всех `/shop/api/*`, тела `/cart`, Console, скрины и сырые заголовки: `cookie` запроса и `set-cookie` ответа (`Network.*ExtraInfo`). Без OTP, без PAN, «Оплатить» не нажималась, профиль Арама не трогали. База — `fly ssh` + `bin/rails runner` в транзакции `READ ONLY` (`transaction_read_only` = on).

Прогоны (все на v518): [`after/`](after/) — первый прогон a, b, d · [`after_pwa/`](after_pwa/) — диагностика (a, d повторно) · [`after_logged/`](after_logged/) — финальный полный прогон a + b + d под живым `fly logs`. Вердикты одинаковые во всех трёх.

## До / после

| | v517 (до) | v518 (после) |
|---|---|---|
| A → B → снова B → A | в B сброс, но повторный B — снова `cart_reset` и баннер; в A **вернулась корзина A** (`items: 1`) | в B сброс один раз, повторный B — без сброса, в A **корзина пустая** |
| Read-only `/shop/api/*` с cookie | `Set-Cookie` на каждом ответе (`expire_after`) | без `Set-Cookie` |
| `/config`, `/tenants` | плавающий 500 (до перезапуска Neon) | 200 |

## Сценарии

| | Что | Результат | Вердикт |
|---|---|---|---|
| **a** TASK_120 A → B → B → A | товар в A → открыть B → снова B → вернуться в A, подождать опрос 18 с и перезагрузить | A: `POST /cart/add` → 1 шт., 10₽ ([a1](after_logged/a1_point_a_cart_1_item.png)) · **B:** `GET /cart` → `cart_reset: true`, `items: 0`, баннер «Корзина очищена: вы перешли в другую точку», 0₽ ([a2](after_logged/a2_point_b_cart_reset_banner.png)) · **снова B:** `cart_reset` нет, баннера нет ([a3](after_logged/a3_point_b_again_no_banner.png)) · **A:** `items: 0`, `cart_reset` нет, 0₽, `coffeeos_shop_cart_v1` пустая ([a4](after_logged/a4_back_to_a_empty_cart.png)) · после опроса и перезагрузки — по-прежнему пусто ([a5](after_logged/a5_point_a_after_poll_reload_empty.png)) · 3 прогона из 3 одинаково | ✅ |
| **b** гонка с опросом | товар в A, 35 с на каталоге, перезагрузка | за 35 с — 5 циклов опроса (`/orders/active`, `/frequent_products`, `/categories`), все 200 без `set-cookie` · после перезагрузки `GET /cart` → `items: 1`, шторка 10₽, товар в шторке ([b1](after_logged/b1_point_a_after_35s_poll_reload.png)) · 2 прогона из 2 | ✅ |
| **c** заголовки | `set-cookie _coffeeos_session` по эндпоинтам при уже существующей cookie (финальный прогон, a + b + d) | без `set-cookie`: `/config` 0/9, `/tenants` 0/18, `/categories` 0/26, `/frequent_products` 0/45, `/orders/active` 0/28, `/profile` 0/9, `/products/:id` 0/2, `/favorites` 0/2, `POST /environment_events` 0/3 · с `set-cookie`: `POST /cart/add` 2/2, `GET /cart` со сбросом 2/2, `GET /shop` 9/9 — все с `expires` · `GET /cart` без сброса пишет cookie только при самом первом обращении (в сессии ещё нет ключа корзины) — это изменение сессии, так и задумано | ✅ |
| **d** регрессия v517 | каталог, шапка, шторка, beacon TASK_112, `/config` + `/tenants`, Console | каталог/шапка/шторка как в v517 ([d1](after_logged/d1_catalog_point_a_412x915.png)) · `POST /shop/api/environment_events` (Ping) → 204, после перезагрузки всего 1 · в базе с 15:24 UTC 10 строк = 10 чистых профилей прогонов, все Point A, колонки — только флаги · `/config` и `/tenants` → 200 (6/6 в d) · JS-исключений 0; в Console только 401 `/profile` (гость), 404 `favicon`/`uploads` (известно, ISSUES) | ✅ |

**Про «ровно один раз»:** при первом заходе в B витрина шлёт два `GET /cart` одновременно с одной и той же старой cookie — оба отвечают `cart_reset: true` с одинаковым пустым состоянием (так и описано в Subtask 1a, тест `session_stale_snapshot_test.rb`). Баннер на экране один; при повторном заходе в B и в A — ни сброса, ни баннера.

## Найдено попутно — установка service worker пишет старый снимок сессии (🟡, вне scope Патча 1)

- **Что:** при установке service worker витрины (`app/views/shop/pwa/service_worker.js.erb:20`, `cache.addAll(["/shop", …])`) браузер сам запрашивает `GET /shop` (без `tenant_id`) и `GET /shop/service-worker.js` с cookie гостя. Оба ответа идут через контроллеры вне `/shop/api/*` (`Shop::PagesController`, `Shop::PwaController`) и по-прежнему пишут cookie целиком — со снимком сессии на момент запроса. В CDP страницы эти запросы не видны (их делает service worker).
- **Доказательства:** в браузере страница отправляла значения cookie, которые не выдал ни один ответ страницы; в логе Fly ([выдержка](after_logged/fly_logs_shop_excerpt.txt)) в каждом из 3 чистых профилей через ~1 с после первой загрузки — `GET "/shop"` без `tenant_id` + `GET "/shop/service-worker.js"` (15:36:10, 15:37:49, 15:39:02); проба на проде обычными HTTP-запросами ([`probe_empty_cart_cookie.mjs`](probe_empty_cart_cookie.mjs)): `GET /shop/manifest.webmanifest` и `GET /shop/service-worker.js` с cookie → `set-cookie`; сам `GET /cart` после первого обращения cookie не пишет ни последовательно, ни параллельно. Манифест браузер запрашивает без cookie — не влияет.
- **Когда может мешать:** установка service worker — один раз на устройство при первом заходе и после каждого деплоя с новыми фронтенд-ассетами (`vite_manifest_cache_version`). Если ровно в эту ~1 секунду гость меняет корзину (или это первый заход после деплоя сразу в другую точку с непустой корзиной), ответ установки может вернуть прежнее состояние корзины. В прогонах a/b этого не случилось (установка шла на первой загрузке, до действий с корзиной).
- **Варианты (решение владельца):** запросы установки без cookie (`credentials: "omit"` для `/shop` в `cache.addAll`) или не писать cookie в `Shop::PwaController`; либо принять как редкий случай. Код не менялся.

## Пачка приёмки

- **Fly logs:** буфер `fly logs --no-tail` — только последние 100 строк (15:35:04+), окно деплоя 15:22–15:35 целиком не поднять; живой хвост 15:35:04–15:39:26 UTC (1175 строк, финальный прогон): 200 ×200, 204 ×3, 401 ×10 (`/shop/api/profile` гостя), **5xx 0, `PreparedStatementCacheExpired` 0**; `RoutingError` 51 — `/uploads/*` и `favicon` (известно, ISSUES) · лог деплоя: release_command OK, обе машины started, health passing
- **Sentry 24h:** по CoffeeOS — 0 issues (в организации нерешённые только `PARKOUR-AM-4`, `PARKOUR-AM-5` — другой проект)
- **Neon Monitoring:** skip — Neon MCP требует авторизации, в консоль не входили (миграций нет, PSCE в логах 0)
- **УК лента Point A:** skip — нужен вход в УК, паролем не входим
- **Fly MCP Point A:** **PASS** (a ✅, b ✅, c ✅, d ✅)

## Не проверено здесь

- Настоящий переход между двумя торговыми точками через шапку (на проде одна точка; B — кухня).
- Android E2E TASK_92 Патч 1–2 (у владельца; шаг 6 не блокирует).
- Поведение после установки PWA на устройстве (только headless Chrome).
