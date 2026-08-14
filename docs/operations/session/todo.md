# todo — #64 /shop в Telegram / Instagram In-App Browser

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| push `41b22c12` (#64 GREEN + пайплайн rules) | ждать CI / deploy | CI green · Fly deploy по апруву · **пачка** Sentry+логи+MCP · TG/IG |

**ТЗ:** [`customer_tasks/Исправление открытия shop во встроенных браузерах Telegram и Instagram.md`](../milestones/veha_2/requirements/customer_tasks/Исправление%20открытия%20shop%20во%20встроенных%20браузерах%20Telegram%20и%20Instagram.md)
**Артефакты:** [`artifacts/shop_telegram_instagram_inapp_browser/`](../milestones/veha_2/artifacts/shop_telegram_instagram_inapp_browser/)
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`
**Diag:** [`diag/chrome_point_a_2026-08-14.md`](../milestones/veha_2/artifacts/shop_telegram_instagram_inapp_browser/diag/chrome_point_a_2026-08-14.md)

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] Диагностика Chrome Point A: HTML+module+mount+каталог PASS; вечный skeleton = module не исполнен / mount throw, classic fallback не было
- [x] RED
- [x] GREEN — watchdog + try/catch mount + Catalog «Повторить» + storage/API tests; без UA-веток
- [ ] REVIEW / Fly MCP Point A / TG/IG устройства

## Файлы (ожидаемо)

- `app/frontend/entrypoints/application.js`
- `app/views/layouts/shop.html.erb`
- `app/frontend/routes/Catalog.svelte`
- `app/frontend/lib/stores/catalog.js`
- `app/frontend/lib/api.js`
- `app/frontend/lib/shopLocalStorage.js` (уже try/catch; тест throw)
- `docs/integrations/shop-api.md` § Embedded browser

## Не ломать

- обычное `/shop` в Chrome Desktop / Chrome Android / Safari iOS
- catalog API + `tenant_id` в query
- CartSheet / peek / «повторить»
- Rails session / CSRF, без глобального CORS «на всякий случай»

## Проверка

- `node --test test/javascript/shop_local_storage_test.mjs test/javascript/shop_catalog_load_test.mjs` — 5/0 PASS
- `bundle exec ruby -Itest test/integration/shop/shop_boot_skeleton_test.rb` — 3/0 PASS

Fly MCP Point A — после deploy (апрув). TG/IG — реальные устройства.
