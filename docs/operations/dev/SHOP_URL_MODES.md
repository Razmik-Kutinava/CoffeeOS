# Витрина: URL точек (два режима)

**Канон продукта:** у каждой точки свой **поддомен = `tenants.slug`**. Витрина: `https://{slug}.{SHOP_BASE_DOMAIN}/shop`.  
Код: `Platform::TenantOnboarding::UrlBuilder`, резолв tenant: `Shop::Concerns::TenantResolution` + `tenant_id_for_host`.

**Не отменяем поддомены** — на Fly demo временно другой **режим стенда** (нет своего DNS/TLS).

---

## Режимы

| | **A. Прод / сеть (целевой)** | **B. Fly demo (сейчас)** |
|---|------------------------------|---------------------------|
| **Когда** | Свой домен подключён | App `coffeeos` на `coffeeos.fly.dev` без домена |
| **`SHOP_BASE_DOMAIN`** | `shop.бренд.ru` (пример) | **не задавать** |
| **URL витрины** | `https://demo-point-a.shop.бренд.ru/shop` | `https://coffeeos.fly.dev/shop?tenant_id=<uuid>` |
| **Flash в УК** | Поддомен по slug | `?tenant_id=` |
| **DNS** | `*.shop.бренд.ru` CNAME → `coffeeos.fly.dev` | Не нужен |
| **TLS** | `fly certs add "*.shop.бренд.ru"` + `_acme-challenge` | Только apex `coffeeos.fly.dev` (авто Fly) |
| **Проверка slug** | Host → `Tenant.slug` | `tenant_id` в query (slug в БД тот же) |

### Что **не** работает на Fly (зафиксировано 2026-05-25)

```bash
fly certs add "*.coffeeos.fly.dev" -a coffeeos
fly certs add demo-point-a.coffeeos.fly.dev -a coffeeos
# → cannot register certificate for this domain
```

Зона `*.fly.dev` принадлежит Fly; DNS для `{slug}.coffeeos.fly.dev` не создаётся.

---

## Локальная разработка

**Поддомены (как в проде):**

```bash
# .env
SHOP_BASE_DOMAIN=localhost
PORT=3001
```

`/etc/hosts` (или dnsmasq):

```
127.0.0.1 demo-point-a.localhost
127.0.0.1 demo-point-b.localhost
```

Витрина: `http://demo-point-a.localhost:3001/shop`

**Без hosts:** `SHOP_BASE_DOMAIN` пустой → `/shop?tenant_id=...`

---

## Переход B → A (чеклист владельца)

1. Домен у регистратора (например `shop.кофейня.ru`).
2. DNS у провайдера:
   - `*.shop.кофейня.ru` CNAME → `coffeeos.fly.dev`
   - apex по инструкции `fly certs setup` (A/AAAA при необходимости).
3. `fly certs add "*.shop.кофейня.ru" -a coffeeos` → `_acme-challenge` из `fly certs setup` → **Ready**.
4. `fly secrets set SHOP_BASE_DOMAIN=shop.кофейня.ru -a coffeeos` (или `[env]` в `fly.toml` + deploy).
5. `config.hosts` в `production.rb` — добавить `/.*\.shop\.кофейня\.ru\z/` если домен не подпадает под существующие правила.
6. Smoke: 3 slug → 3 URL `https://{slug}.shop.кофейня.ru/shop` открываются, меню разное по точкам.
7. Отметить в `../milestones/veha_2/checklists/CHECKLIST.md` § **F. Инфра URL**.

---

## Команды

```bash
# Все URL витрин для текущего ENV (Fly demo или прод)
bin/rails demo:shop_urls

# На Fly
fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'
```

---

## Связанные документы

| Документ | Содержание |
|----------|------------|
| [`../demo/FLY_DEMO_STAND.md`](../demo/FLY_DEMO_STAND.md) | Режим B: автосид, smoke, откат, **ошибки `fly certs` / `fly ssh`** |
| [`../demo/CUSTOMER_HANDOFF.md`](../demo/CUSTOMER_HANDOFF.md) | Одна страница для заказчика: URL + логины |
| [`../milestones/veha_2/runbooks/INFRA_URLS.md`](../milestones/veha_2/runbooks/INFRA_URLS.md) | ENV, панели, чеклист приёмки |
| [`../milestones/veha_2/runbooks/ONBOARDING.md`](../milestones/veha_2/runbooks/ONBOARDING.md) | Карточка точки, flash URL |
| [`../journal/CHANGELOG.md`](../journal/CHANGELOG.md) | История решений |
