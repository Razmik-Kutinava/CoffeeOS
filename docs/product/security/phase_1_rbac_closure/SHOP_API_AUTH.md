# IB Phase 1 / V3-SEC-SHOP-API-KEYS — Shop API Auth Model

**Фаза:** 1 + security follow-up · обновлено: 2026-09-09

Документ описывает **как клиенты авторизуются** на `/shop/api/*`, tenant-scoped API keys и ротацию.

См. также: [SHOP_API_ACCESS_MATRIX.md](../phase_0_baseline/SHOP_API_ACCESS_MATRIX.md) · [OrderOwnership concern](../../../app/controllers/concerns/shop/api/order_ownership.rb)

---

## Режимы доступа к Shop API

Код: `config/initializers/shop_api_auth.rb` → `Shop::Api::Auth` · `Shop::ApiKeyAuthenticator`.

| Режим | Когда | Gate | Scope |
|-------|--------|------|--------|
| **Browser PWA (vitrina)** | Запрос из `/shop` в браузере | `Referer` содержит `/shop` **и** валидный `X-CSRF-Token` | без API key (ключ в meta/JS **не** отдаём) |
| **Server / curl / MCP / kiosk proxy** | Нативный клиент, бэкенд-прокси | **только** header `X-Shop-Api-Key` | ключ → `tenant_id` **должен** совпасть с resolved shop tenant |
| **Ops global** | MCP/acceptance bootstrap | тот же header; запись `global_ops: true` или ENV fallback | любой tenant; warn в лог; **не** для клиентских приложений |
| **Test** | `Rails.env.test?` | auth **skip** (только тесты; не prod/staging) | — |
| **Public catalog** | `GET /shop/api/categories` | `skip authenticate_shop_api!` | публичный каталог |

**Запрещено:** `?api_key=` / body `api_key` → **401** (утечка в логи/Referer).

Tenant: param `tenant_id` → header `X-Shop-Tenant` → `SHOP_DEFAULT_TENANT_ID`. Все экшены под `around_action :with_shop_tenant!` + RLS. Auth `before_action` внутри around → `Current.tenant_id` уже задан.

---

## Модель `shop_api_keys`

Таблица: digest only (`token_digest` = SHA-256 hex). Сырой ключ **не** хранить и **не** логировать.

| Поле | Смысл |
|------|--------|
| `tenant_id` | UUID точки; **null** только при `global_ops` |
| `token_digest` | unique |
| `token_prefix` | 6–8 символов для UI/debug без секрета |
| `active` / `revoked_at` / `expires_at` | ротация и отзыв |
| `global_ops` | ops-only ключ на все точки |

RLS: isolation по `app.current_tenant_id` + lookup policy `app.shop_api_key_lookup` через `Rls::GucContext.with_shop_api_key_lookup` (как device tokens — **без** `row_security off`).

Выдача: `rails shop:api_keys:issue[<tenant_uuid>,name]` → печатает RAW один раз в stdout.

---

## ENV bootstrap / Fly secrets

| Secret | Назначение |
|--------|------------|
| `SHOP_API_KEY` | Legacy global. Пока нет per-tenant ключей (или до `SHOP_API_KEY_FALLBACK=0`) — принимается как **global_ops** с warn в лог. MCP/`ShopApiKeyResolver` читает его же. |
| `SHOP_API_KEY_FALLBACK=0` | Выключить ENV fallback после seed per-tenant ключей |

**Рекомендуемый ops Point A:**

1. `rails shop:api_keys:issue[<Point A uuid>,mcp]` → сохранить raw в password manager.
2. Fly: положить raw Point A в `SHOP_API_KEY` **или** оставить ENV только для fallback и передавать tenant-key в MCP-скриптах через тот же secret (resolver пока берёт `SHOP_API_KEY` — не ломает `bin/acceptance/*`).
3. Когда все точки на digest-ключах — `SHOP_API_KEY_FALLBACK=0`, revoke старых ENV-only клиентов.

Filter logs: `:api_key`, `:shop_api_key` в `filter_parameter_logging.rb`.

---

## Ротация (без даунтайма)

1. `shop:api_keys:issue` — новый ключ (current); previous остаётся `active`.
2. Обновить клиенты (Fly secret / MCP).
3. Через 24–48 ч: `revoked_at` / `active=false` на previous.
4. Опционально: `expires_at` на old key.

---

## Ownership (Phase 1)

После API gate — для **личных** данных (заказ, оплата, профиль):

- `Shop::Api::OrderOwnership` — `order_visible_to_session?` / `find_visible_order!`
- Условия visibility: `customer_id` в сессии · `PendingOrderSession` (guest checkout) · `reconnect_token`
- Чужой заказ по UUID → **404** `{ error: "Order not found" }` (не 403)
- `GET orders/:id` без customer и без reconnect → **401** (без изменений)

**Out of scope:** kiosk `/kiosk/api/auth` device tokens, Flutter OAuth/JWT, Platform CRUD UI.

---

## OTP login vs saved cards (V3-SEC-OTP-MERGE)

- **OTP (phone/email)** = login-фактор: сессия переключается на существующий verified-профиль (`switch`), а не «гость поглощает донора с картами».
- **Saved cards / one-click / SBP AccountToken** = отдельный контур: после входа в профиль с `MobilePaymentMethod` списание блокируется до `Payments::BindingStepUp` unlock в этой сессии (`step_up_required: true`).
- `CustomerProfileMerger.merge!` по умолчанию **не** переносит карты (`allow_payment_methods: false`); явный allow — только для осознанных сценариев (`link_email!` / `link_phone!`).

---

## Чеклист для нового shop/api endpoint

1. Класс данных: PUBLIC / GUEST / CUSTOMER?
2. Если `order_id` или PII → `find_visible_order!` или `require_customer!`
3. Обновить matrix в `SHOP_API_ACCESS_MATRIX.md`
4. IDOR test в `test/integration/shop/api/ownership_idor_test.rb` при новом order-scoped action
