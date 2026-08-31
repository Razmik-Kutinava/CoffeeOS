# Flutter — мобилка, киоск, Shop API

**Единственный документ** по Flutter и клиентскому API. Обновлено: 2026-05-30.

**Backend:** готов. **Flutter UI:** **В3** (отдельный репозиторий).

| Слой | Статус |
|------|--------|
| `POST /kiosk/api/auth` | ✅ `c44b1eb` |
| Shop API (меню, корзина, заказ, оплата) | ✅ |
| Т-Банк + callback + barista табло | ✅ см. CHECKLIST §C |
| Регистрация киоска в manager/devices | ✅ |
| Flutter app (телефон + планшет) | ❌ ждёт app |

Один pipeline заказа (`Shop::OrderCreator`, Т-Банк, webhook). Flutter **не** ходит в банк напрямую — открывает `payment_url` в WebView.

---

## Как задаётся точка

| Канал | `tenant_id` |
|-------|-------------|
| **Мобилка** | Пользователь выбирает точку → header `X-Shop-Tenant` |
| **Киоск** | `POST /kiosk/api/auth` с `device_token` → в ответе `tenant_id` → дальше shop API |

---

## Base URL

| Стенд | URL |
|-------|-----|
| Prod | `https://coffeeos.fly.dev` |
| Local | `http://localhost:3000` |

---

## Авторизация shop API

| Header | Когда |
|--------|--------|
| `X-Shop-Tenant` | UUID точки — **обязателен** |
| `X-Shop-Api-Key` | Нативный app без browser session — значение `SHOP_API_KEY` (Fly secrets) |
| `X-CSRF-Token` + cookie | Только браузерная витрина `/shop` |

**Корзина** хранится в Rails **session** — нативный клиент должен сохранять cookies между `cart/*` и `orders` (или позже — stateless cart API).

---

## Kiosk auth

Токен: **manager → Devices → «Создать киоск»** на нужной точке.

```http
POST /kiosk/api/auth
X-Device-Token: <device_token>
Content-Type: application/json
```

**200:**

```json
{
  "tenant_id": "2fdee1ac-4674-41ee-b89e-87b45643f789",
  "tenant_name": "Demo Coffee Point A",
  "tenant_slug": "demo-point-a",
  "device_id": "...",
  "device_name": "Front kiosk",
  "kiosk_settings": {
    "allow_card": true,
    "allow_cash": true,
    "idle_timeout_seconds": 300,
    "welcome_text": "Добро пожаловать",
    "display_settings": {}
  }
}
```

**401** — нет/неверный токен, устройство не `kiosk` или неактивно.

---

## Shop API

Все запросы: `X-Shop-Tenant` + `X-Shop-Api-Key` (prod).

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/shop/api/categories` | Категории |
| GET | `/shop/api/products` | Каталог (`{ data: [...], meta }`) |
| GET | `/shop/api/products/:id` | Карточка |
| POST | `/shop/api/cart/add` | В корзину |
| GET | `/shop/api/cart` | Корзина |
| PATCH | `/shop/api/cart/items/:index` | Кол-во (`delta`) · **B1.13-S4:** + `selected_modifiers` (edit из Product) |
| DELETE | `/shop/api/cart/items/:index` | Удалить |
| POST | `/shop/api/orders` | Создать заказ |
| GET | `/shop/api/orders/:id` | Статус |
| GET | `/shop/api/orders/history` | История (нужен customer session) |

### POST `/shop/api/orders`

```json
{
  "name": "Гость",
  "phone": "+79001234567",
  "payment_method": "card",
  "comment": ""
}
```

`payment_method`: `card` | `sbp` | `cash`

| Метод | Ответ |
|-------|--------|
| `card` / `sbp` | `status: pending_payment`, `payment_url: https://pay.tbank.ru/...` |
| `cash` | `status: accepted`, `payment_url: null` |

После оплаты банк → webhook → order `accepted` → barista табло (live broadcast).

---

## Demo (Fly prod)

| | |
|--|--|
| Demo A `tenant_id` | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| Demo B `tenant_id` | `655aaccb-004a-4bb9-a50a-ce618854dda3` |
| Витрина (браузер) | `https://coffeeos.fly.dev/shop?tenant_id=<uuid>` |
| Manager | `shift-a@demo.coffeeos.local` / `demo123456` |
| Barista A | `barista-a@demo.coffeeos.local` / `demo123456` |

---

## Prod smoke (curl, без Flutter)

Проверка backend: **token → auth → shop API → barista табло**.

Секреты **не коммитить**: `SHOP_API_KEY` из `fly secrets list` / `ENV` (не из HTML meta); `DEVICE_TOKEN` из manager.

> **Корзина:** сначала `GET /shop?tenant_id=…` (cookie), дальше все запросы с `-c/-b`. JSON body — `--data-binary @file.json` (PowerShell ломает inline JSON).  
> **CSRF:** Shop API с `X-Shop-Api-Key` не требует CSRF-токена (`skip_forgery_protection`); `null_session` без токена обнулял session — см. прогон 7 в `QA_ACCEPTANCE_RUN.md`.

```bash
export BASE="https://coffeeos.fly.dev"
export SHOP_API_KEY="<fly secrets / ENV>"
export DEVICE_TOKEN="<manager/devices>"
export COOKIE_JAR="/tmp/kiosk-smoke-cookies.txt"
rm -f "$COOKIE_JAR"

# 0) Session cookie
curl -s -c "$COOKIE_JAR" "$BASE/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789" -o /dev/null

# 1) Auth
export TENANT_ID=$(curl -s -X POST "$BASE/kiosk/api/auth" \
  -H "X-Device-Token: $DEVICE_TOKEN" | jq -r .tenant_id)

# 2) Каталог
export PRODUCT_ID=$(curl -s "$BASE/shop/api/products" \
  -H "X-Shop-Tenant: $TENANT_ID" \
  -H "X-Shop-Api-Key: $SHOP_API_KEY" | jq -r '.data[0].id')

# 3) Корзина (cookie jar!) — JSON из файла
printf '{"product_id":"%s","quantity":1,"selected_modifiers":[]}\n' "$PRODUCT_ID" > /tmp/cart_add.json
curl -s -X POST "$BASE/shop/api/cart/add" \
  -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -H "X-Shop-Tenant: $TENANT_ID" \
  -H "X-Shop-Api-Key: $SHOP_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/cart_add.json | jq .

curl -s "$BASE/shop/api/cart" \
  -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -H "X-Shop-Tenant: $TENANT_ID" \
  -H "X-Shop-Api-Key: $SHOP_API_KEY" | jq .

# 4) Заказ cash → accepted
printf '{"name":"Kiosk Smoke","phone":"+79001234567","payment_method":"cash"}\n' > /tmp/order_cash.json
curl -s -X POST "$BASE/shop/api/orders" \
  -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -H "X-Shop-Tenant: $TENANT_ID" \
  -H "X-Shop-Api-Key: $SHOP_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/order_cash.json | jq .

# 5) Barista: /barista → заказ в ACCEPTED без F5
```

**Локальная страховка (не prod):**

```bash
bin/rails test test/integration/shop/api/cart_persistence_test.rb
```

Ожидание: `1 run, 5 assertions, 0 failures`. На Windows без WSL — если PG на `:5432` недоступен, см. `DATABASE_PORT` / WSL в `QA_ACCEPTANCE_RUN.md` прогон 7.

**Card без списания:** заказ с `"payment_method":"card"` → `pending_payment`; callback на Fly:

```bash
fly ssh console -a coffeeos -C "bin/rake fly:callback_smoke"
```

*(Rake создаёт свой card-заказ; pipeline тот же.)*

---

## Flutter app — когда стартуем

- Один проект: **мобилка + tablet UI** (киоск)
- Киоск: при старте app → `device_token` (provisioning) → `/kiosk/api/auth` → shop API
- Мобилка: выбор точки → `X-Shop-Tenant`
- Оплата: WebView на `payment_url`
- Офлайн/Drift — по необходимости, не блокирует MVP

---

## Shop API — tenant / адрес (B1.14)

### `GET /shop/api/config`

Дополнительные поля:

```json
{
  "tenant": {
    "id": "uuid",
    "name": "Demo Coffee Point A",
    "city": "Москва",
    "address": "ул. Ленина, 10",
    "display_address": "Москва, ул. Ленина, 10"
  },
  "last_ordered_tenant_id": "uuid-or-null"
}
```

`display_address` = «Город, Адрес»; если оба пустые — `"Адрес не указан"`.

### `GET /shop/api/tenants`

Все активные точки продаж (`sales_point`, `status=active`) в **том же городе**, что текущая (нормализация `city`, без фильтра по организации). Порядок: **текущая** → **ближайшие** по `latitude`/`longitude` (haversine) → точки без координат (по имени). `switchable: true`, если в городе больше одной точки. Гость и авторизованный — одинаковый список; `last_ordered_tenant_id` — только для залогиненного покупателя (история mobile-заказов).

Заголовок: `X-Shop-Tenant` (текущая точка из URL).

```json
{
  "current_tenant_id": "uuid",
  "last_ordered_tenant_id": "uuid-or-null",
  "switchable": true,
  "tenants": [
    {
      "id": "uuid",
      "name": "Demo Coffee Point A",
      "city": "Москва",
      "address": "ул. Ленина, 10",
      "display_address": "Москва, ул. Ленина, 10",
      "is_current": true,
      "distance_km": null
    },
    {
      "id": "uuid",
      "name": "Demo Coffee Point C",
      "city": "Москва",
      "address": "ул. Тверская, 12",
      "display_address": "Москва, ул. Тверская, 12",
      "is_current": false,
      "distance_km": 0.42
    }
  ]
}
```

**Демо:** `demo-point-a`, `demo-point-b` (org `demo-coffeeos`), `demo-point-c` (org `demo-coffeeos-alt`) — Москва, разные цены (+0/+10/+20 ₽) и расписание.

---

## Позже (не в контракте)

- Customer JWT / mobile login
- Refund API — В3
- Stateless cart без session cookie
