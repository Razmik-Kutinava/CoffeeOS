# todo — #65 связка Telegram / Instagram In-App → CoffeeOS /shop

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| CI green `c9b8f04d` | REVIEW+push done | **deploy — апрув** · потом MCP |

**CBR:** #65  
**ТЗ:** [`customer_tasks/Изменения в связке Telegram Instagram In-App Browser к CoffeeOS shop.md`](../milestones/veha_2/requirements/customer_tasks/Изменения%20в%20связке%20Telegram%20Instagram%20In-App%20Browser%20к%20CoffeeOS%20shop.md)  
**Артефакты:** [`artifacts/telegram_instagram_inapp_shop_linkage/`](../milestones/veha_2/artifacts/telegram_instagram_inapp_shop_linkage/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 2 (связка). #64 MCP не закрыт этим шагом.

## Цель (1 предложение)

Гарантировать, что переход из TG/IG In-App по ссылке `/shop?tenant_id=` сохраняет тот же `tenant_id` до `/shop/api/categories`, без auth через UA/TG identity и без forced redirect в Chrome.

## Acceptance (DoD)

1. **Identity:** только `tenant_id` из query → внутренний tenant; TG/IG user_id/username/phone/UA **не** auth для `/shop`.
2. **Целостность связки:** `tenant_id` с внешней ссылки = `@shop_tenant` / meta на HTML `/shop` = query на `GET /shop/api/categories` (FE `withTenantQuery`). Потеря/подмена = ошибка связки (не тихий fallback «другая точка»).
3. **Errors (уже частично #64 — проверить/добить тестами связки):**
   - нет вечного `shop-boot-skeleton` без controlled fallback;
   - API 4xx/5xx/network → error + «Повторить»;
   - localStorage throw → каталог через API;
   - API down + валидный cache → cache;
   - storage R/W error сам по себе не роняет `loadCatalog`/bootstrap.
4. **External browser:** предложение открыть URL снаружи — **только** если diag доказал, что конкретный WebView объективно не тянет `/shop`; forced redirect **не** основной фикс.
5. **Security:** CSRF глобально не отключать; CORS глобально не добавлять без proof; секреты TG/IG не в frontend.
6. **Диагностика:** цепочка HTML → JS → mount → router → `tenant_id` → API → JSON → state → render; отличие Chrome vs embedded в `artifacts/.../diag/` — **до** platform-specific костылей.
7. **Вне scope:** платежи, SMS/Callcheck, auth funnel, контракты TG/IG, user identity через мессенджеры.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] Диагностика связки (local): явный blank/unknown `tenant_id` → ошибка, не silent fallback; Chrome/TG устройства — после deploy
- [x] RED — `fa2a7f84`
- [x] GREEN — export helpers · explicit `tenant_id` key · docs § integrity
- [x] REVIEW / Fly MCP Point A / TG-IG
  - REVIEW manual `[x]` · Fly MCP `[ ]` · TG-IG `[ ]`

## Файлы (ожидаемо)

- `app/frontend/lib/api.js` — `resolvedShopTenantId` / `withTenantQuery`: query `tenant_id` обязан уходить в categories
- `app/controllers/shop/concerns/tenant_resolution.rb` — серверный resolve; query побеждает; silent fallback ≠ «подмена» при явном `tenant_id` в ссылке
- `app/controllers/shop/api/base_controller.rb` — 422/404 при отсутствии/неверном tenant для API
- `app/controllers/shop/pages_controller.rb` — HTML `/shop` резолвит тот же `tenant_id` из query → `@shop_tenant` / meta
- `app/frontend/lib/stores/catalog.js` — cache/API fallback (регрессия #64 в контексте связки)
- `docs/integrations/shop-api.md` § Embedded browser — контракт связки (точки входа, identity, integrity, errors)
- `test/javascript/shop_api_tenant_query_test.mjs` + `test/integration/shop/shop_tenant_linkage_test.rb` + categories `?tenant_id=`

## Не ломать

- обычное `/shop` в Chrome Desktop / Chrome Android / Safari iOS (без TG)
- #64 boot watchdog / Catalog «Повторить» / storage throw → loadCatalog
- CartSheet / peek / «повторить»
- Rails CSRF глобально; без «глобального CORS»
- платежи / auth / SMS — вне scope

## Проверка

- `node --test test/javascript/shop_api_tenant_query_test.mjs test/javascript/shop_catalog_load_test.mjs test/javascript/shop_local_storage_test.mjs` — **9/0 PASS**
- `bundle exec ruby -Itest test/integration/shop/api/categories_controller_test.rb` — **7/0 PASS**
- `bundle exec ruby -Itest test/integration/shop/shop_tenant_linkage_test.rb` — **3/0 PASS**
- `bundle exec ruby -Itest test/integration/shop/shop_boot_skeleton_test.rb` — **3/0 PASS**

Fly MCP Point A — после deploy (апрув). TG/IG на телефонах — отдельно.

## Риски / заметки

- Явный `params.key?(:tenant_id)` (даже пустой) блокирует fallback — без ключа fallbacks как раньше.
- Не плодить UA-ветки «если Telegram».
- Не смешивать закрытие #64 MCP с кодом #65.
