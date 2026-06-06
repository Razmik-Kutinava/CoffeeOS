# Handoff: УК → Меню → витрины A/B (2026-06-04)

**Для следующей сессии агента:** читай этот файл первым, если задача про меню УК, витрину, PTS, polling.

**Связь:** [`SESSION_STATE.md`](../../session/SESSION_STATE.md) · [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) · MCP [`artifacts/demo-feedback/mcp_uk_menu_autorefresh_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_uk_menu_autorefresh_fly_2026-06-04.json)

---

## Статус (после deploy на Fly)

| Что | Статус |
|-----|--------|
| УК → новый товар + модификаторы + цена (браузер) | **Работает** |
| API витрин A и B сразу после create | **Работает** (проверено `OPS-POSTDEPLOY-001`) |
| Витрины без F5 | **Работает**, polling **8 с** (худший случай ~16 с) |
| Заход в Меню «для починки» | **Не нужен** в обычном сценарии (браузер + deploy `1861f4f`) |

**Стенд:** https://coffeeos.fly.dev  
**УК:** `uk@demo.coffeeos.local` / `demo123456` → `/admin/menu`  
**Витрина A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Витрина B:** `https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3`

---

## Коммиты (цепочка фичи)

| SHA | Суть |
|-----|------|
| `589e397` | PTS на все точки + `per_page=50` в API категорий |
| `e398981` | Polling каталога 8s на витрине; cache bust при модификаторах в УК |
| `1861f4f` | PTS sync **вне** транзакции `save` в `PublishProductService`; цена PTS из `base_price` |

**Ветка:** `develop` (запушено ранее в сессии; перед новым deploy сверить `git log origin/develop -3`).

---

## Как работает (простыми словами)

1. УК сохраняет товар → `PublishProductService` + `ProductTenantSync` → **ProductTenantSetting** на каждую точку.
2. Сбрасывается кэш shop API (`bust_shop_catalog_cache!`).
3. Открытые витрины каждые **8 с** заново запрашивают `/shop/api/categories` (без F5).
4. При открытии **УК → Меню** (`repair_catalog_pts_if_needed!`) — дозаполнение PTS для старых/битых записей (страховка).

**Код:**

- `app/services/platform/menu/product_tenant_sync.rb`
- `app/services/platform/menu/publish_product_service.rb`
- `app/controllers/platform/menu_controller.rb`
- `app/frontend/lib/stores/catalog.js` — `CATALOG_POLL_MS = 8_000`
- `app/controllers/shop/api/categories_controller.rb` — default `per_page` 50

**Rake:** `bin/rails platform:menu:sync_pts` (на Fly: `fly ssh console -a coffeeos -C "bin/rails platform:menu:sync_pts"`).

---

## MCP / проверки на Fly

- **Автообновление без F5:** PASS — цена 199→259₽ на A/B; карточки OPS-DEPLOY на DOM ≤16 s.
- **Создание через браузер:** `OPS-POSTDEPLOY-001` в API на **A и B** без repair.
- **curl-скрипты** (`tmp_*` в корне, **не в git**): create через curl иногда не попадает в API — для приёмки использовать **форму в браузере**.

---

## Сценарий для демо / QA

1. Открыть витрины A и B (две вкладки).
2. УК → Меню → категория → название, цена, «Активен» → **Добавить товар**.
3. Раскрыть товар → группа модификаторов → опции с `price_delta`.
4. **Не жать F5** — через ~8 s карточка на обеих витринах.
5. Изменить цену в УК → на витринах обновится за ~8 s.

---

## Дальше (не блокер меню)

- §I веха 2: живое демо, закрытие §E формально.
- Хвост: успех **реальной** оплаты + история заказов; физический подвал.
- **Апрув:** push/deploy — по решению владельца репо (последний код ops в коммите docs этой сессии).

---

## Не коммитить

- `tmp_*.sh`, `tmp_*.py`, `tmp_pdf_extract.txt`, `-b` — локальные артефакты сессии.
