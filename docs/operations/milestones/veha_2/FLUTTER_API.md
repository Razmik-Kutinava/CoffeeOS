# Flutter / Shop API — контракт для мобилки и киоска

**Статус:** 2026-05-30. Backend готов; Flutter UI — отдельный репозиторий.

**Связанные:** [`KIOSK.md`](KIOSK.md), [`PAYMENT.md`](PAYMENT.md), [`CHECKLIST.md`](CHECKLIST.md) §D.

---

## Модель

| Канал | Как задаётся точка (`tenant_id`) |
|-------|----------------------------------|
| **Мобилка** | Пользователь выбирает точку → app шлёт `X-Shop-Tenant` (или `tenant_id` в query) |
| **Киоск (планшет)** | `POST /kiosk/api/auth` с `device_token` → получает `tenant_id` → дальше shop API |

Один pipeline заказа и оплаты (`Shop::OrderCreator`, Т-Банк, callback). Flutter **не** ходит в банк напрямую.

---

## Base URL

| Стенд | URL |
|-------|-----|
| Prod (Fly) | `https://coffeeos.fly.dev` |
| Local | `http://localhost:3000` |

---

## Авторизация shop API

| Header | Когда |
|--------|--------|
| `X-Shop-Tenant` | UUID точки — **обязателен** для нативного app (или `?tenant_id=` в query) |
| `X-Shop-Api-Key` | Нативный клиент без browser session — значение из `SHOP_API_KEY` (Fly secrets) |
| `X-CSRF-Token` + cookie session | Только браузерная витрина `/shop` |

---

## Kiosk auth

```http
POST /kiosk/api/auth
X-Device-Token: <token из manager/devices>
Content-Type: application/json
```

**Ответ 200:**

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

**401** — нет токена, неверный токен, устройство не `kiosk` или неактивно.

Токен создаётся в **manager → Devices → создать киоск**.

---

## Shop API (меню → заказ → оплата)

Все запросы с `X-Shop-Tenant: <tenant_id>` (+ `X-Shop-Api-Key` для app).

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/shop/api/categories` | Категории |
| GET | `/shop/api/products` | Каталог |
| GET | `/shop/api/products/:id` | Карточка товара |
| POST | `/shop/api/cart/add` | В корзину |
| GET | `/shop/api/cart` | Корзина |
| PATCH | `/shop/api/cart/items/:index` | Кол-во |
| DELETE | `/shop/api/cart/items/:index` | Удалить строку |
| POST | `/shop/api/orders` | Создать заказ |
| GET | `/shop/api/orders/:id` | Статус заказа |
| GET | `/shop/api/orders/history` | История (нужен `shop_customer_id` в session) |

### POST `/shop/api/orders`

**Body (JSON):**

```json
{
  "name": "Гость",
  "phone": "+79001234567",
  "payment_method": "card",
  "comment": ""
}
```

`payment_method`: `card` | `sbp` | `cash`

**Ответ 200 (card/sbp):**

```json
{
  "order_id": "...",
  "total": 179.0,
  "discount": 0.0,
  "status": "pending_payment",
  "payment_url": "https://pay.tbank.ru/..."
}
```

**Ответ 200 (cash):**

```json
{
  "order_id": "...",
  "status": "accepted",
  "payment_url": null
}
```

App открывает `payment_url` во WebView / browser. После оплаты банк шлёт webhook на Rails → order `accepted` → барista табло.

---

## Demo tenant (Fly)

| Точка | `tenant_id` |
|-------|-------------|
| Demo A | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| Demo B | `655aaccb-004a-4bb9-a50a-ce618854dda3` |

Витрина: `https://coffeeos.fly.dev/shop?tenant_id=<uuid>`

---

## Prod smoke (без Flutter)

```bash
# 1) Auth киоска (token из manager)
curl -s -X POST https://coffeeos.fly.dev/kiosk/api/auth \
  -H "X-Device-Token: TOKEN" | jq .

# 2) Меню
curl -s "https://coffeeos.fly.dev/shop/api/products" \
  -H "X-Shop-Tenant: TENANT_UUID" \
  -H "X-Shop-Api-Key: KEY"

# 3) Callback worker path (на машине Fly)
bin/rake fly:callback_smoke
```

---

## Не в этом контракте (позже)

- `GET /shop/api/tenants` — список точек для экрана «выбери кофейню» (когда будет UI выбора)
- Customer JWT / mobile login — пока session или guest checkout
- Refund API — В3
