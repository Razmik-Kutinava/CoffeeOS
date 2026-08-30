# IB Phase 1 — Shop API Auth Model

**Фаза:** 1 (shop ownership closure) · дата: 2026-08-30

Документ описывает **как клиенты авторизуются** на `/shop/api/*` и план ротации API-ключа. Реализация multi-key **не входит** в Phase 1.

См. также: [SHOP_API_ACCESS_MATRIX.md](../phase_0_baseline/SHOP_API_ACCESS_MATRIX.md) · [OrderOwnership concern](../../../app/controllers/concerns/shop/api/order_ownership.rb)

---

## Режимы доступа к Shop API

Код: `config/initializers/shop_api_auth.rb` → `Shop::Api::Auth`.

| Режим | Когда | Gate |
|-------|--------|------|
| **Browser PWA (vitrina)** | Запрос из `/shop` в браузере | `Referer` содержит `/shop` **и** валидный `X-CSRF-Token` (same-origin cookie session) |
| **Server / mobile / kiosk (future)** | Нативный клиент, бэкенд-прокси | `X-Shop-Api-Key` или query `api_key` == `ENV["SHOP_API_KEY"]` |
| **Test** | `Rails.env.test?` | auth **skip** (только тесты; не prod/staging) |
| **Public catalog** | `GET /shop/api/categories` | `skip authenticate_shop_api!` — намеренно публичный каталог |

Tenant: param `tenant_id` → header `X-Shop-Tenant` → `SHOP_DEFAULT_TENANT_ID`. Все экшены под `around_action :with_shop_tenant!` + RLS.

---

## Ownership (Phase 1)

После API gate — для **личных** данных (заказ, оплата, профиль):

- `Shop::Api::OrderOwnership` — `order_visible_to_session?` / `find_visible_order!`
- Условия visibility: `customer_id` в сессии · `PendingOrderSession` (guest checkout) · `reconnect_token`
- Чужой заказ по UUID → **404** `{ error: "Order not found" }` (не 403)
- `GET orders/:id` без customer и без reconnect → **401** (без изменений)

**Out of scope Phase 1:** kiosk `/kiosk/api/auth`, Flutter clients, staff Pundit, ABAC.

---

## План ротации `SHOP_API_KEY` (ops, без автоматизации)

Multi-key в коде **не реализован**. Ротация — ручная, владелец/ops:

| Шаг | Действие | Кто |
|-----|----------|-----|
| 1 | Сгенерировать новый ключ (32+ байт, cryptographically random) | Ops |
| 2 | Добавить новый ключ в Fly secrets / `.env` staging как **активный** `SHOP_API_KEY` | Ops |
| 3 | Deploy приложения (после CI green, **с апрувом владельца**) | Ops |
| 4 | Обновить клиентов, использующих API key (если появятся kiosk/server интеграции) | Dev + ops |
| 5 | Мониторинг 401 на старых клиентах 24–48 ч | Ops |
| 6 | Revoke: старый ключ удалить из secrets (единственный ключ в env) | Ops |

**Частота:** по инциденту или планово 1×/год для server key (когда появятся non-browser клиенты).

**Browser PWA** не использует `SHOP_API_KEY` — ротация CSRF/session не затрагивает этот документ.

---

## Чеклист для нового shop/api endpoint

1. Класс данных: PUBLIC / GUEST / CUSTOMER?
2. Если `order_id` или PII → `find_visible_order!` или `require_customer!`
3. Обновить matrix в `SHOP_API_ACCESS_MATRIX.md`
4. IDOR test в `test/integration/shop/api/ownership_idor_test.rb` при новом order-scoped action
