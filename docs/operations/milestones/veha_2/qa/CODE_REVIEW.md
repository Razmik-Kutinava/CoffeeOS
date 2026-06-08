# Code review Веха 2

**Дата:** 2026-05-30  
**Ветка:** `develop`  
**Цель:** качество и риски перед **прогоном 10** (MCP/curl) и prod-оплатой. Образец: [`../veha_1/CODE_REVIEW.md`](../veha_1/CODE_REVIEW.md).

**Скоуп:** онбординг УК, Т-Банк, kiosk API, shop API, RLS/`Current`, Rack::Attack.

**Чеклист проекта:** `.cursor/rules/project/coffeeos-performance.mdc`, `coffeeos-core.mdc`.

---

## Что делали

| Шаг | Действие | Результат |
|-----|----------|-----------|
| 1 | Ревью кода по блокам скоупа | Таблица находок ниже |
| 2 | Правки по CR (минимальный дифф) | V2-002, V2-004, V2-005, SEC-09 |
| 3 | `bin/rails test` (WSL) | **554 runs, 2301 assertions, 0 failures** |
| 4 | MCP DevTools | **не перегоняли** — следующий шаг: **прогон 10** |

---

## Итог ревью

**Вердикт:** **можно к прогону 10** (MCP/curl, без живых денег). Блокеров безопасности для текущего Fly-стенда (1 web + worker) не осталось после правок. **§I не закрыта** (живое demo, DEMO_FEEDBACK).

---

## Находки

| ID | Severity | Файл | Находка | Действие |
|----|----------|------|---------|----------|
| V2-002 | Major | `shop/order_creator.rb` | N+1: `exists?` на PTS в цикле корзины | **Исправлено:** `shop_available_product_ids` — один запрос FOR SHARE |
| V2-004 | Major | `tbank_callback_job.rb` | Широкий `.or(provider: tbank)` — риск неверного Payment | **Исправлено:** strict PaymentId; fallback только pending без id |
| V2-005 | Major | `tbank_controller.rb` | Idempotency после enqueue (TOCTOU) | **Исправлено:** `CacheCounter.claim` до enqueue |
| SEC-09 | Major | `rack_attack.rb` | Throttle kiosk на `/api/kiosk/` — маршрут `/kiosk/api/` | **Исправлено:** path + throttle IP на auth |
| V2-001 | Major | `catalog_bootstrap.rb` | N+1 PTS при bootstrap каталога | **Исправлено** *(2026-06-01, блок 1)* — prefetch + create! |
| V2-003 | Major | `kiosk/api/auth_controller.rb` | `KioskSetting` без tenant GUC после RLS off | **Исправлено** *(2026-06-02, блок 3)* — `with_kiosk_tenant_guc!` |
| V2-004b | Major | `tbank_callback_job.rb` | Job без `SET LOCAL tenant` | **Принято** — DB owner bypass; документировано (как V1 jobs) |
| SEC-01 | P0 | `events_controller.rb` | Auth skip если callback secrets пусты | **Принято** — prod: secrets в Fly (`CALLBACK_SHARED_SECRET`, `CALLBACK_SHARED_TOKEN`); T-Bank через `/callbacks/tbank`. Блок 4: manual-check перед deploy |
| SEC-02 | P0 | `shop_api_auth.rb` | `browser_shop_session?` без verify CSRF | **Исправлено** *(2026-06-01, блок 2)* — `valid_authenticity_token?` |
| SEC-03 | P1 | `cache_counter.rb` | MemoryStore — не cluster-safe | **Принято** — 1 web pod Fly; multi-pod → Solid/Redis (В3) |
| SEC-06 | P2 | `tenant_resolution.rb` | `X-Shop-Tenant` без auth | **Принято** — публичная витрина по UUID/slug; изоляция по tenant_id |
| SEC-07 | P2 | `shop.html.erb` | API key в meta | **Принято** — демо-стенд; backlog подтверждён (блок 4) |
| SEC-08 | P2 | `orders_controller.rb` | `show` без проверки customer | **Исправлено** *(2026-06-01, блок 2)* — только `session[:shop_customer_id]` |
| V2-006 | Minor | `entry_points.rb` | Дубли FeatureFlag запросов | **Исправлено** *(2026-06-01)* — один `where` + index_by |
| V2-007 | Minor | `products_controller.rb` | `find_by!` без rescue | OK — `show` ловит RecordNotFound |
| V2-008 | Minor | `order_creator.rb` | Init вне txn | **Принято** — void_pending + job fallback |
| V2-009 | Minor | `shop_api_auth.rb` | `params[:api_key]` | **Принято** — header preferred |
| V2-010 | Minor | `kiosk/auth` | token в params | **Принято** — header primary |
| V2-011 | Minor | `tenant_resolution.rb` | fallback first tenant | **Принято** — dev; prod `SHOP_DEFAULT_TENANT_ID` / host |
| — | OK | `tenant_onboarding/provision.rb` | SET LOCAL через quote, rollback | Без изменений |
| — | OK | `tenants_controller.rb` | транзакция, includes | Без изменений |
| — | OK | `tbank_adapter.rb` | Token verify, circuit breaker | Без изменений |
| — | OK | `shop/api/base_controller.rb` | skip_forgery + tenant txn | Без изменений |
| — | OK | `payment_status_updater.rb` | lock, idempotent accept | Без изменений |

---

## Тесты после ревью

```text
bin/rails test test/services/shop/order_creator_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/shop/api/cart_persistence_test.rb
# 32 runs, 59 assertions, 0 failures

bin/rails test
# 554 runs, 2301 assertions, 0 failures (WSL, 2026-05-30)
```

| Прогон | Runs | Failures |
|--------|------|----------|
| targeted (shop + tbank + cart) | 32 | **0** |
| полный suite | **554** | **0** |

---

## Следующие шаги

1. **Прогон 10** — этапы 0–2 **PASS** 2026-06-01; **добивка** — блоки 1–14 в [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md) (прогона 11 **нет**).
2. **Техдолг CR** (V2-CR-01…05 в [`PRACTICES.md`](PRACTICES.md)) → фиксы в рамках **прогона 10** (блоки 1–5).  
   **Gate блока 5:** suite WSL **559/0** *(2026-06-02)*.
3. **Живое demo** — только §I чеклиста, не прогон 10.
4. §I — postmortem (блок 14), затем фидбек §E, апрув, SESSION_STATE/CHANGELOG.

**Связанные доки:** [`CHECKLIST.md`](CHECKLIST.md) §I, [`PRACTICES.md`](PRACTICES.md), [`PAYMENT.md`](PAYMENT.md).
