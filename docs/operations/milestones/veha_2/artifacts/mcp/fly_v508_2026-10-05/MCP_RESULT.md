# Fly v508 — post-deploy (9 патчей 2026-10-05)

**Date:** 2026-10-05 · **HEAD** `c878c8bf` · **Fly** v508 `deployment-01M469FBK4ZVXX158XCAF46C75` (15:09 UTC)  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**CI:** [`37329291576`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37329291576) + Semgrep `37329291374` + CodeQL `37329291584` green на `c878c8bf`  
**Deploy:** GitHub Actions [`37329668626`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37329668626) (workflow_dispatch, `develop`)  
**Сводный crit-audit:** `47be43cc..c878c8bf` (28 файлов кода, 2 миграции) — `CLEAN`, см. `CRITICAL_LEDGER.md`  
**Local перед деплоем:** JS 690 — 60 fail = legacy (те же 3 набора: #71 email gate, sticky cancel, personal cabinet [RED])

## Пачка приёмки

| Где | Результат |
|-----|-----------|
| **Migration** | `20261005120000` (receipt_email) + `20261005140000` (card_binding_attempts.source + backfill) применены · версия БД `20261005140000` |
| **Fly** | web+worker v508 · health fail на буте Puma → 1/1 passing · `/up`, `/shop?tenant_id=…`, `/login` = 200 · панели `/barista` `/manager` `/admin` `/prep_kitchen` → 302 `/login` · `/tv_board?token=…` 200 · 5xx/Exception в логах нет |
| **Sentry** | skip — Sentry MCP в этой сессии недоступен; проверить вручную Issues → Unresolved → 24h |
| **Neon / УК** | skip |

## Задачи → проверка на проде

| Задача | Проверка | Статус |
|--------|----------|--------|
| TASK_100 — тексты ошибки оплаты + отдельный CTA | бандл: «Недостаточно средств» ×2, «Попробовать позже» ×1, «Повторить оплату» ×1 | **PASS** bundle; live — skip (нужна реальная неуспешная оплата) |
| TASK_101 — «Итого» в шторке способов оплаты | бандл: `payment-methods-order-total` ×1 | **PASS** bundle; live — skip (шторка = one-click оплата живой картой заказчика) |
| TASK_86 Патч 1 — WAITING сам уходит в результат | live: `#/payment-result?status=waiting&order_id=X` → hash `status=fail` того же X → «Оплата не завершена, попробовать снова» без reload; чужой `order_id` → экран не меняется | **PASS** live — [скрин](task86_waiting_to_fail.png) |
| TASK_90 Патч 1 — авто-подписка после настроек | бандл: `pageshow` ×8 | **PASS** bundle; device Android/Chrome — заказчик |
| TASK_37 Патч 1 — CSP SW Firebase | `GET /firebase-messaging-sw.js`: 200, `Cache-Control: no-store`, CSP с `www.gstatic.com`, ETag разный на каждый ответ · Chrome: `serviceWorker.register` → `activated` | **PASS** live |
| #71 Патч_2 — `receipt_email` | колонка есть; неподтверждённых email у гостей с телефоном 0; код `profile_controller` / `email_service` в контейнере; бандл `receipt_email` ×2 | **PASS** (данные + код); live профиль — skip (в браузере нет серверной сессии гостя, 401) |
| ЛК Патч 3 — нет иконки поддержки в шапке | DOM 1613 px и 390 px: `shop-header-support-chat` = 0, в header только «Профиль»; бандл 0 | **PASS** live — [скрин 390](shop_390_header.png) |
| TASK_94 Патч 1 — Повторить из ЛК | бандл: `history:` ×3 | **PASS** bundle; live — skip (Повторить = one-click списание) |
| TASK_102 (#75 Патч 1) — промо 11 ₽ не повторно | backfill: `backfill_pre_promo` = 4 · dry_run `to_create: 0` · 19 сохранённых карт/СБП, непокрытых журналом 0 | **PASS** (данные) |
| Табло бариста A | login barista-a → `/barista`, смена открыта, `#202609-0035` на табло | **PASS** — [скрин](barista_a_board.png) |

Не замечено регрессий. Подпись «Итого» в свёрнутой CartSheet прижата к левому краю — так же на v505 ([скрин](../fly_v505_2026-10-01/point_a_shop.png)), CartSheet в этих патчах не менялся → не регресс v508.

## Ссылки

- Витрина A: https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789
- Вход в панели: https://coffeeos.fly.dev/login (бариста `/barista`, менеджер `/manager`, УК `/admin`, цех `/prep_kitchen`)
- ТВ-табло A: `https://coffeeos.fly.dev/tv_board?token=<device_token tv_board «зал»>`

## Next

- Sentry 24h вручную (MCP недоступен)
- Глазами заказчика на телефоне: ошибки оплаты/«Итого» (TASK_100/101), WebPush Android (TASK_37/90), Повторить в ЛК (TASK_94)
