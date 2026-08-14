# todo — #64 /shop в Telegram / Instagram In-App Browser

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Intake + SPEC #64 | SPEC готов, причина не доказана | Диагностика точки отказа (Chrome эталон → TG/IG) |

**ТЗ:** [`customer_tasks/Исправление открытия shop во встроенных браузерах Telegram и Instagram.md`](../milestones/veha_2/requirements/customer_tasks/Исправление%20открытия%20shop%20во%20встроенных%20браузерах%20Telegram%20и%20Instagram.md)
**Артефакты:** [`artifacts/shop_telegram_instagram_inapp_browser/`](../milestones/veha_2/artifacts/shop_telegram_instagram_inapp_browser/)
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

53 subtask ТЗ = матрица диагностики, не 53 коммита. Задачи 2–5 серии — другие диалоги.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [ ] Диагностика: эталон Chrome → TG/IG Android/iOS → точка отказа в цепочке HTML → JS → mount → router → tenant_id → API → render
- [ ] RED — тесты на найденную причину + fallback (storage / API error / bootstrap)
- [ ] GREEN — фикс доказанной причины; без UA-веток и без redirect «открой в Chrome»
- [ ] REVIEW — INTEGRATIONS.md § связка TG/IG → /shop; отчёт Причина / Доказательство / Исправление / Проверка; убрать debug hooks

## Файлы (ожидаемо)

- `app/frontend/entrypoints/application.js` — mount; если JS падает до mount, вечный `shop-boot-skeleton`
- `app/views/shop/pages/home.html.erb` — server-rendered skeleton
- `app/frontend/App.svelte` — router `/` → Catalog; module-level init
- `app/frontend/routes/Catalog.svelte` — loadCatalog / error UX / «Повторить»
- `app/frontend/lib/stores/catalog.js` — API + cache fallback + polling
- `app/frontend/lib/shopLocalStorage.js` — storage exceptions
- `app/frontend/lib/api.js` — tenant_id query + fetch catalog

Blast-radius (только если диагностика подтвердит):

- `app/views/layouts/shop.html.erb` — `vite_javascript_tag "application"`, CSP meta
- `app/frontend/lib/cartSheetStore.js` — `refreshCartSheet()` на mount Catalog

## Не ломать

- обычное `/shop` в Chrome Desktop / Chrome Android / Safari iOS
- catalog API + `tenant_id` в query
- CartSheet / peek / «повторить»
- Rails session / CSRF, без глобального CORS «на всякий случай»

## Проверка

- `node --test test/javascript/shop_local_storage_test.mjs test/javascript/shop_catalog_load_test.mjs` (второй файл — после RED)
- `bin/rails test test/integration/shop/pwa_manifest_test.rb test/integration/shop/api/tenant_isolation_test.rb`

**Не** `npm test tests/integration/TASK-N.test.ts` и **не** `npx tsc --noEmit` — не стек репо.
**Не** полный `test/integration/shop/` на Windows.

Fly MCP Point A — после GREEN + deploy (апрув). TG/IG — реальные устройства.

## Диагностика (сжать ТЗ A–F)

- [ ] Chrome Desktop эталон (HTML + JS + mount + каталог)
- [ ] Chrome Android / Safari iOS эталон
- [ ] Telegram Android / iOS — точный симптом
- [ ] Instagram Android / iOS — точный симптом
- [ ] Общая vs платформенная точка отказа
- [ ] Bundle / chunks / CSP только если Network это показал
- [ ] tenant_id / redirects / API / cookies / CSRF / CORS — только по факту

## Resilience (после причины, если ещё дыры)

- [ ] вечный `shop-boot-skeleton` → error fallback
- [ ] API error → loading=false + «Повторить»
- [ ] storage unavailable не роняет каталог
- [ ] cache fallback при живом cache
