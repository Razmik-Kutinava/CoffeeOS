# Code review Веха 2

**Дата:** 2026-05-30  
**Ветка:** `develop`  
**Цель:** качество и риски перед **прогоном 10** (MCP/curl) и prod-оплатой. Образец: [`../veha_1/CODE_REVIEW.md`](../veha_1/CODE_REVIEW.md).

**Скоуп:** онбординг УК, Т-Банк, kiosk API, shop API, RLS/`Current`, Rack::Attack.

**Чеклист проекта:** `.cursor/rules/coffeeos-performance.mdc`, `coffeeos-core.mdc`.

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
| V2-001 | Major | `catalog_bootstrap.rb` | N+1 PTS при bootstrap каталога | **Отложено** — онбординг редкий; perf-тест → прогон 10 / В3 |
| V2-003 | Major | `kiosk/api/auth_controller.rb` | `KioskSetting` без tenant GUC после RLS off | **Отложено** — owner bypass RLS; при FORCE RLS — fix в В3 |
| V2-004b | Major | `tbank_callback_job.rb` | Job без `SET LOCAL tenant` | **Принято** — DB owner bypass; документировано (как V1 jobs) |
| SEC-01 | P0 | `events_controller.rb` | Auth skip если `CALLBACK_*` пуст | **Принято** — prod: secrets в Fly; T-Bank через `/callbacks/tbank`. Проверить secrets на deploy |
| SEC-02 | P0 | `shop_api_auth.rb` | `browser_shop_session?` без verify CSRF | **Принято** — same-origin Svelte + session cart; смена сломает витрину → отдельная задача |
| SEC-03 | P1 | `cache_counter.rb` | MemoryStore — не cluster-safe | **Принято** — 1 web pod Fly; multi-pod → Solid/Redis (В3) |
| SEC-06 | P2 | `tenant_resolution.rb` | `X-Shop-Tenant` без auth | **Принято** — публичная витрина по UUID/slug; изоляция по tenant_id |
| SEC-07 | P2 | `shop.html.erb` | API key в meta | **Принято** — демо-стенд; ротация ключей → backlog |
| SEC-08 | P2 | `orders_controller.rb` | `show` без проверки customer | **Отложено** — низкий риск при opaque UUID; усилить в В3 |
| V2-006 | Minor | `entry_points.rb` | Дубли FeatureFlag запросов | Не трогали |
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

1. **Прогон 10** — [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md) (3×3, AUTH, stress, kiosk curl).
2. Фиксы по прогону 10 → **прогон 11** при необходимости.
3. **Живое demo** (этап 3) — отложено.
4. §I — postmortem, SESSION_STATE, апрув заказчика.

**Связанные доки:** [`CHECKLIST.md`](CHECKLIST.md) §I, [`PRACTICES.md`](PRACTICES.md), [`PAYMENT.md`](PAYMENT.md).
